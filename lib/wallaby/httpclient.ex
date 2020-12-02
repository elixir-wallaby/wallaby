defmodule Wallaby.HTTPClient do
  @moduledoc false

  alias Wallaby.Query

  @type method :: :post | :get | :delete
  @type url :: String.t()
  @type params :: map | String.t()
  @type cookies :: [String.t()] | []
  @type request_opts :: [{:encode_json, boolean}, {:cookies, cookies}]
  @type response :: map
  @type web_driver_error_reason :: :stale_reference | :invalid_selector | :unexpected_alert

  @status_obscured 13
  # The maximum time we'll sleep is for 50ms
  @max_jitter 50

  @doc """
  Sends a request to the webdriver API and parses the
  response.
  """
  @spec request(method, url, params, request_opts) ::
          {:ok, response}
          | {:error, web_driver_error_reason | Jason.DecodeError.t() | String.t()}
          | no_return

  def request(method, url, params \\ %{}, opts \\ [])

  def request(method, url, params, opts) when map_size(params) == 0 do
    make_request(method, url, "", opts)
  end

  def request(method, url, params, [{:encode_json, false} | opts]) do
    make_request(method, url, params, opts)
  end

  def request(method, url, params, opts) do
    make_request(method, url, Jason.encode!(params), opts)
  end

  defp make_request(method, url, body, opts), do: make_request(method, url, body, opts, 0, [])

  @spec make_request(method, url, String.t() | map, request_opts(), non_neg_integer(), [
          String.t()
        ]) ::
          {:ok, response, cookies}
          | {:error, web_driver_error_reason | Jason.DecodeError.t() | String.t()}
          | no_return
  defp make_request(_, _, _, _, 5, retry_reasons) do
    ["Wallaby had an internal issue with HTTPoison:" | retry_reasons]
    |> Enum.uniq()
    |> Enum.join("\n")
    |> raise
  end

  defp make_request(method, url, body, opts, retry_count, retry_reasons) do
    req_cookies = inject_cookies(opts)

    method
    |> HTTPoison.request(url, body, headers(), request_opts(req_cookies))
    |> handle_response
    |> case do
      {:error, :httpoison, error} ->
        :timer.sleep(jitter())

        make_request(
          method,
          url,
          body,
          opts,
          retry_count + 1,
          [inspect(error) | retry_reasons]
        )

      result ->
        result
    end
  end

  @spec handle_response({:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}) ::
          {:ok, response, cookies}
          | {:error, web_driver_error_reason | Jason.DecodeError.t() | String.t()}
          | {:error, :httpoison, HTTPoison.Error.t()}
          | no_return
  defp handle_response(resp) do
    case resp do
      {:error, %HTTPoison.Error{} = error} ->
        {:error, :httpoison, error}

      {:ok, %HTTPoison.Response{status_code: 204, headers: headers}} ->
        {:ok, %{"value" => nil}, parse_cookies(headers)}

      {:ok, %HTTPoison.Response{body: body, headers: headers}} ->
        with {:ok, decoded} <- Jason.decode(body),
             {:ok, response} <- check_status(decoded),
             {:ok, validated} <- check_for_response_errors(response),
             do: {:ok, validated, parse_cookies(headers)}
    end
  end

  @spec check_status(response) :: {:ok, response} | {:error, String.t()}
  defp check_status(response) do
    case Map.get(response, "status") do
      @status_obscured ->
        message = get_in(response, ["value", "message"])

        {:error, message}

      _ ->
        {:ok, response}
    end
  end

  @spec check_for_response_errors(response) ::
          {:ok, response}
          | {:error, web_driver_error_reason}
          | no_return
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp check_for_response_errors(response) do
    case Map.get(response, "value") do
      %{"class" => "org.openqa.selenium.StaleElementReferenceException"} ->
        {:error, :stale_reference}

      %{"message" => "Stale element reference" <> _} ->
        {:error, :stale_reference}

      %{"message" => "stale element reference" <> _} ->
        {:error, :stale_reference}

      %{
        "message" =>
          "An element command failed because the referenced element is no longer available" <> _
      } ->
        {:error, :stale_reference}

      %{"message" => "invalid selector" <> _} ->
        {:error, :invalid_selector}

      %{"class" => "org.openqa.selenium.InvalidSelectorException"} ->
        {:error, :invalid_selector}

      %{"class" => "org.openqa.selenium.InvalidElementStateException"} ->
        {:error, :invalid_selector}

      %{"message" => "unexpected alert" <> _} ->
        {:error, :unexpected_alert}

      %{"error" => _, "message" => message} ->
        raise message

      _ ->
        {:ok, response}
    end
  end

  defp request_opts(cookies) do
    Application.get_env(:wallaby, :hackney_options, hackney: [pool: :wallaby_pool])
    |> Keyword.merge(timeout: 20_000, recv_timeout: 30_000)
    |> add_hackney_options(cookies)
  end

  @spec add_hackney_options(Keyword.t(), cookies()) :: Keyword.t()
  defp add_hackney_options(opts, []) do
    opts
  end

  defp add_hackney_options(opts, cookies) do
    hackney =
      case Keyword.fetch(opts, :hackney) do
        {:ok, value} -> value
        _ -> []
      end

    hackney = Keyword.merge(hackney, cookie: format_cookies(cookies))
    Keyword.merge(opts, hackney: hackney)
  end

  defp headers do
    [{"Accept", "application/json"}, {"Content-Type", "application/json"}]
  end

  @spec to_params(Query.compiled()) :: map
  def to_params({:xpath, xpath}) do
    %{using: "xpath", value: xpath}
  end

  def to_params({:css, css}) do
    %{using: "css selector", value: css}
  end

  defp jitter, do: :rand.uniform(@max_jitter)

  @spec inject_cookies(Keyword.t()) :: cookies()
  defp inject_cookies([{:cookies, cookies} | _]) do
    cookies
  end

  defp inject_cookies(_), do: []

  @spec parse_cookies([{String.t(), String.t()}]) :: cookies()
  defp parse_cookies(headers) do
    headers
    |> Enum.filter(fn {key, _} -> String.match?(key, ~r/\Aset-cookie\z/i) end)
    |> Enum.map(fn {_key, value} -> value end)
  end

  @spec format_cookies(cookies()) :: String.t()
  defp format_cookies(cookies), do: Enum.join(cookies, "; ")
end
