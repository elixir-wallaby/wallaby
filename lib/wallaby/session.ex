defmodule Wallaby.Session do
  defstruct [:id, :base_url, :server]

  def create(server) do
    base_url = Wallaby.Server.get_base_url(server)

    params = %{
      desiredCapabilities: %{
        javascriptEnabled: false,
        version: "",
        rotatable: false,
        takesScreenshot: true,
        cssSelectorsEnabled: true,
        browserName: "phantomjs",
        nativeEvents: false,
        platform: "ANY"
      }
    }

    response = request(:post, "#{base_url}session", params)
    session = %Wallaby.Session{base_url: base_url, id: response["sessionId"], server: server}
    {:ok, session}
  end

  def request(method, url, params \\ %{}) do
    headers = [{"Content-Type", "text/json"}]
    body = case params do
      params when map_size(params) == 0 -> ""
      params -> Poison.encode!(params)
    end

    {:ok, response} = HTTPoison.request(method, url, body, headers)
    Poison.decode!(response.body)
  end
end
