defmodule Wallaby.Driver do
  alias Wallaby.Session
  alias Wallaby.Node

  @type method :: :post | :get | :delete
  @type url :: String.t
  @type query :: String.t
  @type params :: %{using: String.t, value: query}
  @type locator :: Session.t | Node.t

  @moduledoc """
  List of all endpoints to implement for webdriver protocol

  | Method | URI Template	                                         | Command   |
  | -------|-------------------------------------------------------|-----------|
  | POST	 | /session	New Session
  | DELETE | /session/{session id}	Delete Session
  | POST	 | /session/{session id}/url	Get
  | GET	   | /session/{session id}/url	Get Current URL
  | POST	 | /session/{session id}/back	Back
  | POST	 | /session/{session id}/forward	Forward
  | POST	 | /session/{session id}/refresh	Refresh
  | GET	   | /session/{session id}/title	Get Title
  | GET	   | /session/{session id}/window	Get Window Handle
  | DELETE | /session/{session id}/window	Close Window
  | POST	 | /session/{session id}/window	Switch To Window
  | GET	   | /session/{session id}/window/handles	Get Window Handles
  | POST	 | /session/{session id}/window/fullscreen	Fullscreen Window
  | POST	 | /session/{session id}/window/maximize	Maximize Window
  | POST	 | /session/{session id}/window/size	Set Window Size
  | GET	   | /session/{session id}/window/size	Get Window Size
  | POST	 | /session/{session id}/frame	Switch To Frame
  | POST	 | /session/{session id}/frame/parent	Switch To Parent Frame
  | POST	 | /session/{session id}/element	Find Element
  | POST	 | /session/{session id}/element/{element id}/element	Find Element From Element
  | POST	 | /session/{session id}/elements	Find Elements
  | POST	 | /session/{session id}/element/{element id}/elements	Find Elements From Element
  | GET	   | /session/{session id}/element/active	Get Active Element
  | GET	   | /session/{session id}/element/{element id}/selected	Is Element Selected
  | GET	   | /session/{session id}/element/{element id}/attribute/{name}	Get Element Attribute
  | GET	   | /session/{session id}/element/{element id}/property/{name}	Get Element Property
  | GET	   | /session/{session id}/element/{element id}/css/{property name}	Get Element CSS Value
  | GET	   | /session/{session id}/element/{element id}/text	Get Element Text
  | GET	   | /session/{session id}/element/{element id}/name	Get Element Tag Name
  | GET	   | /session/{session id}/element/{element id}/rect	Get Element Rect
  | GET	   | /session/{session id}/element/{element id}/enabled	Is Element Enabled
  | GET	   | /session/{session id}/source	Get Page Source
  | POST	 | /session/{session id}/execute/sync	Execute Script
  | POST	 | /session/{session id}/execute/async	Execute Async Script
  | GET	   | /session/{session id}/cookie/{name}	Get Cookie
  | POST	 | /session/{session id}/cookie	Add Cookie
  | DELETE | /session/{session id}/cookie/{name}	Delete Cookie
  | DELETE | /session/{session id)/cookie	Delete All Cookies
  | POST	 | /session/{session id}/timeouts	Set Timeout
  | POST	 | /session/{session id}/actions	Perform Actions
  | DELETE | /session/{session id}/actions	Releasing Actions
  | POST	 | /session/{session id}/element/{element id}/click	Element Click
  | POST	 | /session/{session id}/element/{element id}/clear	Element Clear
  | POST	 | /session/{session id}/element/{element id}/sendKeys	Element Send Keys
  | POST	 | /session/{session id}/alert/dismiss	Dismiss Alert
  | POST	 | /session/{session id}/alert/accept	Accept Alert
  | GET	   | /session/{session id}/alert/text	Get Alert Text
  | POST	 | /session/{session id}/alert/text	Send Alert Text
  | GET	   | /session/{session id}/screenshot	Take Screenshot
  | GET	   | /session/{session id}/element/{element id}/screenshot	Take Element Screenshot
  """

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
  Gets the selected value of the element.

  For Checkboxes and Radio buttons it returns the selected option.
  For options selects it returns the selected option
  """
  def selected(node) do
    response = request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/selected")
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

  defp request(method, url, params \\ %{}, opts \\ []) do
    headers = [{"Content-Type", "text/json"}]
    body = case params do
      params when map_size(params) == 0 -> ""
      params when [{:encode_json, false}] == opts -> params
      params -> Poison.encode!(params)
    end

    {:ok, response} = HTTPoison.request(method, url, body, headers)
    Poison.decode!(response.body)
  end
end
