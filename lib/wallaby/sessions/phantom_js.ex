defmodule Wallaby.Sessions.PhantomJS do
  defstruct [:id, :base_url, :server]

  def create(server) do
    base_url = Wallaby.Servers.PhantomJS.get_base_url(server)

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

    case request(:post, "#{base_url}session", params) do
      {:ok, json} ->
        session = %Wallaby.Sessions.PhantomJS{base_url: base_url, id: json["sessionId"], server: server}
        {:ok, session}
      error -> error
    end
  end


  def request(method, url, params \\ %{}) do
    headers = [{"Content-Type", "text/json"}]
    body = case params do
      params when map_size(params) == 0 -> ""
      params -> Poison.encode!(params)
    end

    case HTTPoison.request(method, url, body, headers) do
      {:ok, response} ->
        {:ok, Poison.decode!(response.body)}
      error -> error
    end |> IO.inspect
  end
end

defimpl Wallaby.Session, for: Wallaby.Sessions.PhantomJS do
  import Wallaby.Sessions.PhantomJS

  def visit(%{id: session_id, base_url: base_url}, url) do
    request(:post, "#{base_url}session/#{session_id}/url", %{url: url})
  end

  def page_source(%{id: session_id, base_url: base_url}) do
    request(:get, "#{base_url}session/#{session_id}/source")
  end

  # def click(%{id: session_id, base_url: base_url}, link_or_button) do

  # end

  def find(%{id: session_id, base_url: base_url}, selector) do
    params = %{using: "css selector", value: selector}

    request(:post, "#{base_url}session/#{session_id}/element", params)
  end

  def all(%{id: session_id, base_url: base_url}, selector) do
    params = %{using: "css selector", value: selector}

    request(:post, "#{base_url}session/#{session_id}/elements", params)
  end

  def attribute_value(element, attribute_name) do
    element_id = get_element_id(element)
    session_id = Hound.current_session_id
    make_req(:get, "session/#{session_id}/element/#{element_id}/attribute/#{attribute_name}")
  end

end
