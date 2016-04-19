defmodule Wallaby.Driver do
  @moduledoc """
  Implements the webdriver protocol for Phantomjs
  """

  alias Wallaby.Session
  alias Wallaby.Node

  @type method :: :post | :get | :delete
  @type url :: String.t
  @type query :: String.t
  @type params :: %{using: String.t, value: query}
  @type locator :: Session.t | Node.t

  @doc """
  Creates a new session with the driver.
  """
  def create(server, opts) do
    base_url = Wallaby.Server.get_base_url(server)
    user_agent =
      Wallaby.Phantom.user_agent
      |> Wallaby.Metadata.append(opts[:metadata])

    capabilities = Wallaby.Phantom.capabilities(user_agent: user_agent)
    params = %{desiredCapabilities: capabilities}
    
    response = request(:post, "#{base_url}session", params)
    session = %Wallaby.Session{base_url: base_url, id: response["sessionId"], server: server}
    {:ok, session}
  end

  @doc """
  Finds an element on the page for a session. If an element is provided then
  the query will be scoped to within that element.
  """
  # @spec find_elements(Locator.t, query) :: t

  def find_elements(%Session{base_url: base_url, id: id}=session, query) do
    request(:post, "#{base_url}session/#{id}/elements", to_params(query))
    |> Map.get("value")
    |> Enum.map(&cast_as_node({session, &1}))
  end

  def find_elements(%Node{id: id, session: session}, query) do
    request(:post, "#{session.base_url}session/#{session.id}/element/#{id}/elements", to_params(query))
    |> Map.get("value")
    |> Enum.map(&cast_as_node({session, &1}))
  end

  defp cast_as_node({session, %{"ELEMENT" => id}}) do
    %Wallaby.Node{id: id, session: session}
  end

  @doc """
  Sets the value of an element.
  """
  def set_value(%Node{session: session, id: id}, value) do
    request(:post, "#{session.base_url}session/#{session.id}/element/#{id}/value", %{value: [value]})
  end

  @doc """
  Clears the value in an element
  """
  # @spec clear(Locator.t, query) :: t
  def clear(%Node{session: session, id: id}) do
    request(:post, "#{session.base_url}session/#{session.id}/element/#{id}/clear")
    session
  end

  @doc """
  Clicks an element
  """
  def click(%Node{session: session, id: id}) do
    request(:post, "#{session.base_url}session/#{session.id}/element/#{id}/click")
  end

  @doc """
  Gets the text for an element
  """
  def text(node) do
    resp = request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/text")
    resp["value"]
  end

  @doc """
  Gets the value of an elements attribute
  """
  def attribute(node, name) do
    response = request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/attribute/#{name}")
    response["value"]
  end

  @doc """
  Visits a specific page.
  """
  def visit(session, path) do
    request(:post, "#{session.base_url}session/#{session.id}/url", %{url: path})
    session
  end

  @doc """
  Gets the current url.
  """
  def current_url(session) do
    resp = request(:get, "#{session.base_url}session/#{session.id}/url")
    resp["value"]
  end

  @doc """
  Gets the selected value of the element.

  For Checkboxes and Radio buttons it returns the selected option.
  For options selects it returns the selected option
  """
  def selected(node) do
    response = request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/selected")
    response["value"]
  end

  @doc """
  Checks if the node is being displayed.

  This is based on what is available in phantom and doesn't match the current
  specification.
  """
  def displayed(node) do
    response = request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/displayed")
    response["value"]
  end

  @doc """
  Gets the size of a node.

  This is non-standard and only works in Phantom.
  """
  def size(node) do
    response = request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/size")
    response["value"]
  end

  @doc """
  Gets the height, width, x, and y position of an Element.

  This is based on the standard but currently is un-supported by Phantom.
  """
  def rect(node) do
    response = request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/rect")
    response["value"]
  end

  @doc """
  Takes a screenshot.
  """
  def take_screenshot(session) do
    image_data =
      request(:get, "#{session.base_url}session/#{session.id}/screenshot")
      |> Map.get("value")
      |> :base64.decode

    path = path_for_screenshot
    File.write! path, image_data
    path
  end

  @doc """
  Sets the size of the window.
  """
  def set_window_size(session, width, height) do
    request(
      :post,
      "#{session.base_url}session/#{session.id}/window/#{window_handle(session)}/size",
      %{width: width, height: height})
    session
  end

  @doc """
  Gets the size of the window
  """
  def get_window_size(session) do
    request(
      :get,
      "#{session.base_url}session/#{session.id}/window/#{window_handle(session)}/size")
    |> Map.get("value")
  end

  @doc """
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  def execute_script(session, script, arguments \\ []) do
    request(
      :post,
      "#{session.base_url}session/#{session.id}/execute",
      %{script: script, args: arguments})
    |> Map.get("value")
  end

  @doc """
  Sends a list of key strokes to active element
  """
  def send_keys(session, keys) when is_list(keys) do
    request(
      :post,
      "#{session.base_url}session/#{session.id}/keys",
      Wallaby.Helpers.KeyCodes.json(keys),
      encode_json: false)
  end

  @doc """
  Sends text characters to the active element
  """
  def send_text(session, text) do
    request(
      :post,
      "#{session.base_url}session/#{session.id}/keys",
      %{value: [text]})
  end

  defp path_for_screenshot do
    {hour, minutes, seconds} = :erlang.time()
    {year, month, day} = :erlang.date()

    screenshot_dir = "#{File.cwd!()}/screenshots"
    File.mkdir_p!(screenshot_dir)
    "#{screenshot_dir}/#{year}-#{month}-#{day}-#{hour}-#{minutes}-#{seconds}.png"
  end

  defp window_handle(session) do
    request(:get, "#{session.base_url}session/#{session.id}/window_handle")
    |> Map.get("value")
  end

  defp to_params({:xpath, xpath}) do
    %{using: "xpath", value: xpath}
  end

  defp to_params(css_selector) do
    %{using: "css selector", value: css_selector}
  end

  defp request(method, url, params \\ %{}, opts \\ [])
  defp request(method, url, params, _opts) when map_size(params) == 0 do
    make_request(method, url, "")
  end
  defp request(method, url, params, [{:encode_json, false} | _]) do
    make_request(method, url, params)
  end
  defp request(method, url, params, _opts) do
    make_request(method, url, Poison.encode!(params))
  end

  defp make_request(method, url, body) do
    headers = [{"Content-Type", "text/json"}]
    {:ok, response} = HTTPoison.request(method, url, body, headers)
    Poison.decode!(response.body)
  end
end
