defmodule Wallaby.Experimental.Chrome.Webdriver do
  def create_session(base_url, capabilities) do
    params = %{desiredCapabilities: capabilities}
    request(:post, "#{base_url}session", params)
  end

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
  end

  defp make_request!(method, url, body) do
    case make_request(method, url, body) do
      {:ok, resp} ->
        resp

      {:error, :stale_reference} ->
        raise Wallaby.StaleReferenceException

      {:error, :invalid_selector} ->
        raise Wallaby.InvalidSelector, Poison.decode!(body)

      {:error, e} ->
        raise "There was an error calling: #{url} -> #{e.reason}"
    end
  end

  defp request_opts do
    Application.get_env(:wallaby, :hackney_options, [])
  end

  defp headers do
    [{"Accept", "application/json"},
      {"Content-Type", "application/json"}]
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 204}}) do
    {:ok, %{"value" => nil}}
  end
  defp handle_response({:ok, %HTTPoison.Response{body: body}}) do
    with {:ok, decoded} <- Poison.decode(body),
          {:ok, validated} <- check_for_response_errors(decoded),
          do: {:ok, validated}
  end
  defp handle_response({:error, reason}), do: {:error, reason}


  defp check_for_response_errors(response) do
    case Map.get(response, "value") do
      %{"class" => "org.openqa.selenium.StaleElementReferenceException"} ->
        {:error, :stale_reference}
      %{"class" => "org.openqa.selenium.InvalidSelectorException"} ->
        {:error, :invalid_selector}
      _ ->
        {:ok, response}
    end
  end
end
