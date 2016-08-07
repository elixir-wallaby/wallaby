defmodule Wallaby.Driver do
  @moduledoc """
  Implements the webdriver protocol for Phantomjs
  """

  alias Wallaby.Session
  alias Wallaby.Node
  alias Wallaby.Node.Query

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
    id = response["sessionId"]
    session = %Wallaby.Session{
      session_url: base_url <> "session/#{id}",
      url: base_url <> "session/#{id}",
      id: id,
      server: server
    }
    {:ok, session}
  end

  @doc """
  Finds an element on the page for a session. If an element is provided then
  the query will be scoped to within that element.
  """
  # @spec find_elements(Locator.t, query) :: t

  def find_elements(%Query{parent: parent, query: q}=query) do
    nodes =
      request(:post, parent.url <> "/elements", to_params(q))
      |> Map.get("value")
      |> Enum.map(& cast_as_node(parent, &1) )

    %Query{ query | result: nodes }
  end

  defp cast_as_node(parent, %{"ELEMENT" => id}) do
    %Wallaby.Node{
      id: id,
      session_url: parent.session_url,
      url: parent.session_url <> "/element/#{id}",
      parent: parent,
    }
  end

  @doc """
  Sets the value of an element.
  """
  def set_value(%Node{url: url}, value) do
    request(:post, "#{url}/value", %{value: [value]})
  end

  @doc """
  Clears the value in an element
  """
  # @spec clear(Locator.t, query) :: t
  def clear(%Node{url: url}) do
    request(:post, "#{url}/clear")
  end

  @doc """
  Clicks an element
  """
  def click(%Node{url: url}) do
    request(:post, "#{url}/click")
  end

  @doc """
  Gets the text for an element
  """
  def text(node) do
    resp = request(:get, "#{node.url}/text")
    resp["value"]
  end

  @doc """
  Gets the title of the current page.
  """
  def page_title(session) do
    resp = request(:get, "#{session.url}/title")
    resp["value"]
  end

  @doc """
  Gets the value of an elements attribute
  """
  def attribute(node, name) do
    resp = request(:get, "#{node.url}/attribute/#{name}")
    resp["value"]
  end

  @doc """
  Visits a specific page.
  """
  def visit(session, path) do
    request(:post, "#{session.url}/url", %{url: path})
    session
  end

  @doc """
  Gets the current url.
  """
  def current_url(session) do
    resp = request(:get, "#{session.url}/url")
    resp["value"]
  end

  @doc """
  Gets the selected value of the element.

  For Checkboxes and Radio buttons it returns the selected option.
  For options selects it returns the selected option
  """
  def selected(node) do
    response = request(:get, "#{node.url}/selected")
    response["value"]
  end

  @doc """
  Checks if the node is being displayed.

  This is based on what is available in phantom and doesn't match the current
  specification.
  """
  def displayed(node) do
    response = request(:get, "#{node.url}/displayed")
    response["value"]
  end

  @doc """
  Gets the size of a node.

  This is non-standard and only works in Phantom.
  """
  def size(node) do
    response = request(:get, "#{node.url}/size")
    response["value"]
  end

  @doc """
  Gets the height, width, x, and y position of an Element.

  This is based on the standard but currently is un-supported by Phantom.
  """
  def rect(node) do
    response = request(:get, "#{node.url}/rect")
    response["value"]
  end

  @doc """
  Takes a screenshot.
  """
  def take_screenshot(session) do
    request(:get, "#{session.url}/screenshot")
    |> Map.get("value")
    |> :base64.decode
  end

  @doc """
  Sets the size of the window.
  """
  def set_window_size(session, width, height) do
    request(
      :post,
      "#{session.url}/window/#{window_handle(session)}/size",
      %{width: width, height: height})
    session
  end

  @doc """
  Gets the size of the window
  """
  def get_window_size(session) do
    request(:get, "#{session.url}/window/#{window_handle(session)}/size")
    |> Map.get("value")
  end

  @doc """
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  def execute_script(session, script, arguments \\ []) do
    request(:post, "#{session.url}/execute", %{script: script, args: arguments})
    |> Map.get("value")
  end

  @doc """
  Sends a list of key strokes to active element
  """
  def send_keys(session, keys) when is_list(keys) do
    request(:post, "#{session.url}/keys", Wallaby.Helpers.KeyCodes.json(keys), encode_json: false)
  end

  @doc """
  Sends text characters to the active element
  """
  def send_text(session, text) do
    request(:post, "#{session.url}/keys", %{value: [text]})
  end

  defp window_handle(session) do
    request(:get, "#{session.url}/window_handle")
    |> Map.get("value")
  end

  defp to_params({:xpath, xpath}) do
    %{using: "xpath", value: xpath}
  end
  defp to_params({:css, css}) do
    %{using: "css selector", value: css}
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
