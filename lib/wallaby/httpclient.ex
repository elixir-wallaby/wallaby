defmodule Wallaby.HTTPClient do
  @moduledoc false

  alias Wallaby.Query

  @type method :: :post | :get | :delete
  @type url :: String.t()
  @type params :: map | String.t()
  @type cookies :: [String.t()] | []
  @type request_opts :: [{:encode_json, boolean}, {:cookies, cookies}]
  @type response :: map
  @type web_driver_error_reason ::
          :stale_reference
          | :invalid_selector
          | :unexpected_alert

  @status_obscured 13

  @doc """
  Sends a request to the webdriver API and parses the
  response.
  """
  @spec request(method, url, params, request_opts) ::
          {:ok, response}
          | {
              :error,
              web_driver_error_reason
              | Jason.DecodeError.t()
              | String.t()
            }
          | no_return

  def request(method, url, params \\ %{}, opts \\ [])

  def request(method, url, params, opts) when map_size(params) == 0 do
    make_request(method, url, "", opts)
  end

  def request(method, url, params, opts) do
    case Keyword.get(opts, :encode_json) do
      false ->
        make_request(method, url, params, opts)

      _else ->
        make_request(method, url, Jason.encode!(params), opts)
    end
  end

  @spec make_request(method, url, String.t() | map, request_opts) ::
          {:ok, response, cookies}
          | {
              :error,
              web_driver_error_reason | Jason.DecodeError.t() | String.t()
            }
          | no_return
  defp make_request(method, url, body, opts) do
    req_cookies = inject_cookies(opts)

    method
    |> :httpc.request(
      prep_request(method, url, headers(req_cookies), content_type(), body),
      httpc_http_options(),
      httpc_options()
    )
    |> handle_response
    |> case do
      {:error, :httpc, error} ->
        raise inspect(error)

      result ->
        result
    end
  end

  @spec handle_response(
          {
            :ok,
            {
              {charlist(), non_neg_integer(), charlist()},
              [{charlist(), charlist()}, ...],
              binary()
            }
          }
          | {:error, term()}
        ) ::
          {:ok, response, cookies}
          | {
              :error,
              web_driver_error_reason
              | Jason.DecodeError.t()
              | String.t()
            }
          | {:error, :httpc, term()}
          | no_return
  defp handle_response(resp) do
    case resp do
      {:error, error} ->
        {:error, :httpc, error}

      {:ok, {{_http_version, 204, _status_text}, headers, _body}} ->
        {:ok, %{"value" => nil}, parse_cookies(headers)}

      {:ok, {{_http_version, _status_code, _status_text}, headers, body}} ->
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

  defp prep_request(method, url, headers, _content_type, body)
       when method in ~w[delete get head option put trace]a and
              body in ["", nil] do
    {
      String.to_charlist(url),
      Enum.map(headers, fn {k, v} ->
        {String.to_charlist(k), String.to_charlist(v)}
      end)
    }
  end

  defp prep_request(method, url, headers, content_type, body)
       when method in ~w[delete patch post put]a do
    {url, headers} = prep_request(:get, url, headers, content_type, nil)

    {
      url,
      headers,
      String.to_charlist(content_type),
      body
    }
  end

  defp headers([]), do: [{"Accept", "application/json"}]

  defp headers(cookies) do
    headers([]) ++ [{"Cookie", format_cookies(cookies)}]
  end

  defp content_type, do: "application/json"

  defp httpc_http_options do
    Application.get_env(
      :wallaby,
      :httpc_http_options,
      connect_timeout: 20_000,
      timeout: 30_000
    )
  end

  defp httpc_options do
    Application.get_env(
      :wallaby,
      :httpc_options,
      body_format: :binary
    )
  end

  @spec to_params(Query.compiled()) :: map
  def to_params({:xpath, xpath}) do
    %{using: "xpath", value: xpath}
  end

  def to_params({:css, css}) do
    %{using: "css selector", value: css}
  end

  @spec inject_cookies(Keyword.t()) :: cookies()
  defp inject_cookies(opts) do
    case Keyword.get(opts, :cookies) do
      nil -> []
      cookies -> cookies
    end
  end

  @spec parse_cookies([{String.t(), String.t()}]) :: cookies()
  defp parse_cookies(headers) do
    headers
    |> Enum.filter(fn {key, _value} ->
      String.downcase(to_string(key)) == "set-cookie"
    end)
    |> Enum.map(fn {_key, value} -> to_string(value) end)
  end

  @spec format_cookies(cookies()) :: String.t()
  defp format_cookies(cookies), do: Enum.join(cookies, "; ")
end
