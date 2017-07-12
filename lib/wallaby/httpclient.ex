defmodule Wallaby.HTTPClient do
  @type method :: :post | :get | :delete
  @type url :: String.t
  @type params :: map | String.t
  @type request_opts :: {:encode_json, boolean}

  @doc """
  Sends a request to the webdriver API and parses the
  response.
  """
  @spec request(method, url, params, [request_opts]) :: {:ok, any}
                                                      | {:error, :invalid_selector}
                                                      | {:error, :stale_reference}

  def request(method, url, params \\ %{}, opts \\ [])
  def request(method, url, params, _opts) when map_size(params) == 0 do
    make_request(method, url, "")
  end
  def request(method, url, params, [{:encode_json, false} | _]) do
    make_request(method, url, params)
  end
  def request(method, url, params, _opts) do
    make_request(method, url, Poison.encode!(params))
  end

  defp make_request(method, url, body) do
    HTTPoison.request(method, url, body, headers(), request_opts())
    |> handle_response
    |> case do
         {:error, :httpoison} ->
           make_request(method, url, body)
         result ->
           result
    end
  end

  defp handle_response(resp) do
    case resp do
      {:error, %HTTPoison.Error{}} ->
        {:error, :httpoison}

      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok, %{"value" => nil}}

      {:ok, %HTTPoison.Response{body: body}} ->
        with {:ok, decoded} <- Poison.decode(body),
             {:ok, validated} <- check_for_response_errors(decoded),
          do: {:ok, validated}

      {:ok, _} ->
        raise "Received unexpected HTTPoison response."
    end
  end

  # defp make_request!(method, url, body) do
  #   case make_request(method, url, body) do
  #     {:ok, resp} ->
  #       resp

  #     {:error, :stale_reference} ->
  #       raise Wallaby.StaleReferenceException

  #     {:error, :invalid_selector} ->
  #       raise Wallaby.InvalidSelector, Poison.decode!(body)

  #     {:error, %HTTPoison.Error{}=e} ->
  #       raise "There was an error calling: #{url} -> #{e.reason}"
  #   end
  # end

  defp check_for_response_errors(response) do
    case Map.get(response, "value") do
      %{"class" => "org.openqa.selenium.StaleElementReferenceException"} ->
        {:error, :stale_reference}
      %{"message" => "stale element reference" <> _} ->
        {:error, :stale_reference}
      %{"class" => "org.openqa.selenium.InvalidSelectorException"} ->
        {:error, :invalid_selector}
      %{"class" => "org.openqa.selenium.InvalidElementStateException"} ->
        {:error, :invalid_selector}
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
end
