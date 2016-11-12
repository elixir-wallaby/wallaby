defmodule Wallaby.Phantom.Driver do
  @moduledoc """
  Implements the webdriver protocol for Phantomjs
  """

  alias Wallaby.Session
  alias Wallaby.Node
  alias Wallaby.Node.Query
  alias Wallaby.Phantom.Logger
  alias Wallaby.Phantom.LogStore

  @type method :: :post | :get | :delete
  @type url :: String.t
  @type query :: String.t
  @type params :: %{using: String.t, value: query}
  @type locator :: Session.t | Node.t

  @doc """
  Creates a new session with the driver.
  """
  def create(server, opts) do
    base_url = Wallaby.Phantom.Server.get_base_url(server)
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
  Deletes a session with the driver.
  """
  def delete(session) do
    request(:delete, session.session_url, %{})
  end

  @doc """
  Finds an element on the page for a session. If an element is provided then
  the query will be scoped to within that element.
  """
  # @spec find_elements(Locator.t, query) :: t

  def find_elements(%Query{parent: parent, query: q}=query) do
    check_logs!(parent, fn ->
      nodes =
        request(:post, parent.url <> "/elements", to_params(q))
        |> Map.get("value")
        |> Enum.map(& cast_as_node(parent, &1) )

      %Query{ query | result: nodes }
    end)
  end

  @doc """
  Sets the value of an element.
  """
  def set_value(%Node{url: url}=node, value) do
    check_logs! node, fn ->
      request(:post, "#{url}/value", %{value: [value]})
    end
  end

  @doc """
  Clears the value in an element
  """
  # @spec clear(Locator.t, query) :: t
  def clear(%Node{url: url}=node) do
    check_logs! node, fn ->
      request(:post, "#{url}/clear")
    end
  end

  @doc """
  Clicks an element
  """
  def click(%Node{url: url}=node) do
    check_logs! node, fn ->
      request(:post, "#{url}/click")
    end
  end

  @doc """
  Gets the text for an element
  """
  def text(node) do
    check_logs! node, fn ->
      resp = request(:get, "#{node.url}/text")
      resp["value"]
    end
  end

  @doc """
  Gets the title of the current page.
  """
  def page_title(session) do
    check_logs! session, fn ->
      resp = request(:get, "#{session.url}/title")
      resp["value"]
    end
  end

  @doc """
  Gets the value of an elements attribute
  """
  def attribute(node, name) do
    check_logs!(node, fn ->
      resp = request(:get, "#{node.url}/attribute/#{name}")
      resp["value"]
    end)
  end

  @doc """
  Visits a specific page.
  """
  def visit(session, path) do
    check_logs! session, fn ->
      request(:post, "#{session.url}/url", %{url: path})
      session
    end
  end

  @doc """
  Gets the current url.
  """
  def current_url(session) do
    check_logs! session, fn ->
      resp = request(:get, "#{session.url}/url")
      resp["value"]
    end
  end

  @doc """
  Gets the selected value of the element.

  For Checkboxes and Radio buttons it returns the selected option.
  For options selects it returns the selected option
  """
  def selected(node) do
    check_logs! node, fn ->
      response = request(:get, "#{node.url}/selected")
      response["value"]
    end
  end

  @doc """
  Checks if the node is being displayed.

  This is based on what is available in phantom and doesn't match the current
  specification.
  """
  def displayed(node) do
    check_logs!(node, fn ->
      response = request(:get, "#{node.url}/displayed")
      response["value"]
    end)
  end

  @doc """
  Gets the size of a node.

  This is non-standard and only works in Phantom.
  """
  def size(node) do
    check_logs! node, fn ->
      response = request(:get, "#{node.url}/size")
      response["value"]
    end
  end

  @doc """
  Gets the height, width, x, and y position of an Element.

  This is based on the standard but currently is un-supported by Phantom.
  """
  def rect(node) do
    check_logs! node, fn ->
      response = request(:get, "#{node.url}/rect")
      response["value"]
    end
  end

  @doc """
  Takes a screenshot.
  """
  def take_screenshot(session) do
    check_logs! session, fn ->
      request(:get, "#{session.url}/screenshot")
      |> Map.get("value")
      |> :base64.decode
    end
  end

  @doc """
  Sets the size of the window.
  """
  def set_window_size(session, width, height) do
    check_logs! session, fn ->
      request(
        :post,
        "#{session.url}/window/#{window_handle(session)}/size",
        %{width: width, height: height})
      session
    end
  end

  @doc """
  Gets the size of the window
  """
  def get_window_size(session) do
    check_logs! session, fn ->
      request(:get, "#{session.url}/window/#{window_handle(session)}/size")
      |> Map.get("value")
    end
  end

  @doc """
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  def execute_script(session, script, arguments \\ []) do
    check_logs! session, fn ->
      request(:post, "#{session.url}/execute", %{script: script, args: arguments})
      |> Map.get("value")
    end
  end

  @doc """
  Sends a list of key strokes to active element
  """
  def send_keys(session, keys) when is_list(keys) do
    check_logs! session, fn ->
      request(:post, "#{session.url}/keys", Wallaby.Helpers.KeyCodes.json(keys), encode_json: false)
    end
  end

  @doc """
  Sends text characters to the active element
  """
  def send_text(session, text) do
    check_logs! session, fn ->
      request(:post, "#{session.url}/keys", %{value: [text]})
    end
  end

  @doc """
  Retrieves logs from the browser
  """
  def log(session) do
    resp = request(:post, "#{session.session_url}/log", %{type: "browser"})
    resp["value"]
  end

  @doc """
  Retrives the current page source from session
  """
  def page_source(session) do
    check_logs! session, fn ->
      response = request(:get, "#{session.url}/source")
      response["value"]
    end
  end

  defp window_handle(session) do
    check_logs! session, fn ->
      request(:get, "#{session.url}/window_handle")
      |> Map.get("value")
    end
  end

  defp to_params({:xpath, xpath}) do
    %{using: "xpath", value: xpath}
  end
  defp to_params({:css, css}) do
    %{using: "css selector", value: css}
  end

  def check_logs!(session, fun) do
    return_value = fun.()

    logs = log(session)

    session.session_url
    |> LogStore.append_logs(logs)
    |> Logger.log

    return_value
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
    case HTTPoison.request(method, url, body, headers, [timeout: :infinity, recv_timeout: :infinity]) do
      {:ok, response} ->
        Poison.decode!(response.body)
      {:error, e} ->
        raise "There was an error calling: #{url} -> #{e.reason}"
    end
  end

  defp cast_as_node(parent, %{"ELEMENT" => id}) do
    %Wallaby.Node{
      id: id,
      session_url: parent.session_url,
      url: parent.session_url <> "/element/#{id}",
      parent: parent,
    }
  end
end
