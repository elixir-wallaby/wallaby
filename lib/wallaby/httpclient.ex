defmodule Wallaby.HTTPClient do
  @moduledoc false

  @type method :: :post | :get | :delete
  @type url :: String.t
  @type params :: map | String.t
  @type request_opts :: {:encode_json, boolean}

  @status_obscured 13
  @max_jitter 50 # The maximum time we'll sleep is for 50ms

  @doc """
  Sends a request to the webdriver API and parses the
  response.
  """
  @spec request(method, url, params, [request_opts]) :: {:ok, any}
                                                      | {:error, :invalid_selector}
                                                      | {:error, :stale_reference}
                                                      | {:error, :httpoison}

  def request(method, url, params \\ %{}, opts \\ [])
  def request(method, url, params, _opts) when map_size(params) == 0 do
    make_request(method, url, "")
  end
  def request(method, url, params, [{:encode_json, false} | _]) do
    make_request(method, url, params)
  end
  def request(method, url, params, _opts) do
    make_request(method, url, Jason.encode!(params))
  end

  defp make_request(method, url, body), do: make_request(method, url, body, 0, [])
  defp make_request(_, _, _, 5, retry_reasons) do
    ["Wallaby had an internal issue with HTTPoison:" | retry_reasons]
    |> Enum.uniq()
    |> Enum.join("\n")
    |> raise
  end
  defp make_request(method, url, body, retry_count, retry_reasons) do
    method
    |> HTTPoison.request(url, body, headers(), request_opts())
    |> handle_response
    |> case do
      {:error, :httpoison, error} ->
        :timer.sleep(jitter())
        make_request(method, url, body, retry_count + 1, [inspect(error) | retry_reasons])

      result ->
        result
    end
  end

  defp handle_response(resp) do
    case resp do
      {:error, %HTTPoison.Error{} = error} ->
        {:error, :httpoison, error}

      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok, %{"value" => nil}}

      {:ok, %HTTPoison.Response{body: body}} ->
        with {:ok, decoded} <- Jason.decode(body),
             {:ok, response} <- check_status(decoded),
             {:ok, validated} <- check_for_response_errors(response),
          do: {:ok, validated}
    end
  end

  defp check_status(response) do
    case Map.get(response, "status") do
      @status_obscured ->
        message = get_in(response, ["value", "message"])

        {:error, message}
      _  ->
        {:ok, response}
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp check_for_response_errors(response) do
    case Map.get(response, "value") do
      %{"class" => "org.openqa.selenium.StaleElementReferenceException"} ->
        {:error, :stale_reference}
      %{"message" => "Stale element reference" <> _} ->
        {:error, :stale_reference}
      %{"message" => "stale element reference" <> _} ->
        {:error, :stale_reference}
      %{"message" => "An element command failed because the referenced element is no longer available" <> _} ->
        {:error, :stale_reference}
      %{"message" => "invalid selector" <> _} ->
        {:error, :invalid_selector}
      %{"class" => "org.openqa.selenium.InvalidSelectorException"} ->
        {:error, :invalid_selector}
      %{"class" => "org.openqa.selenium.InvalidElementStateException"} ->
        {:error, :invalid_selector}
      %{"message" => "unexpected alert" <> _} ->
        {:error, :unexpected_alert}
      _ ->
        {:ok, response}
    end
  end

  defp request_opts do
    Application.get_env(:wallaby, :hackney_options, [])
  end

  defp headers do
    [{"Accept", "application/json"},
      {"Content-Type", "application/json"}]
  end

  def to_params({:xpath, xpath}) do
    %{using: "xpath", value: xpath}
  end
  def to_params({:css, css}) do
    %{using: "css selector", value: css}
  end

  defp jitter, do: :rand.uniform(@max_jitter)
end
