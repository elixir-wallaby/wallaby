defmodule Wallaby.Phantom.Driver do
  @moduledoc ~S"""
  Implements the webdriver protocol for Phantomjs
  """

  alias Wallaby.Session
  alias Wallaby.Element
  alias Wallaby.Phantom.Logger
  alias Wallaby.Phantom.LogStore
  alias Wallaby.Webdriver.Client
  alias Wallaby.Phantom. Webdriver.Client, as: PhantomClient

  @spec create(pid, Keyword.t) :: {:ok, Session.t}
  def create(server, opts) do
    base_url = Wallaby.Phantom.Server.get_base_url(server)
    user_agent =
      Wallaby.Phantom.user_agent
      |> Wallaby.Metadata.append(opts[:metadata])

    capabilities = Wallaby.Phantom.capabilities(
      user_agent: user_agent,
      custom_headers: opts[:custom_headers]
    )

    {:ok, response} =  Client.create_session(base_url, capabilities)
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
  @spec delete(Session.t | Element.t) :: {:ok, map}
  def delete(session) do
    Client.delete_session(session)
  end

  @doc """
  Finds an element on the page for a session. If an element is provided then
  the query will be scoped to within that element.
  """
  def find_elements(parent, locator) do
    check_logs! parent, fn ->
      Client.find_elements(parent, locator)
    end
  end

  @doc """
  Sets the value of an element.
  """
  def set_value(%Element{}=element, value) do
     check_logs! element, fn ->
       Client.set_value(element, value)
    end
  end

  @doc """
  Clears the value in an element
  """
  def clear(%Element{}=element) do
    check_logs! element, fn ->
      Client.clear(element)
    end
  end

  @doc """
  Clicks an element
  """
  def click(%Element{}=element) do
    check_logs! element, fn ->
      Client.click(element)
    end
  end

  @doc """
  Gets the text for an element
  """
  def text(element) do
    check_logs! element, fn ->
      Client.text(element)
    end
  end

  @doc """
  Gets the title of the current page.
  """
  def page_title(session) do
    check_logs! session, fn ->
      Client.page_title(session)
    end
  end

  @doc """
  Gets the value of an elements attribute
  """
  def attribute(element, name) do
    check_logs! element, fn ->
      Client.attribute(element, name)
    end
  end

  @doc """
  Visits a specific page.
  """
  def visit(session, path) do
    check_logs! session, fn ->
      Client.visit(session, path)
    end
  end

  @doc """
  Gets the current url.
  """
  def current_url(session) do
    check_logs! session, fn ->
      Client.current_url(session)
    end
  end

  def current_url!(session) do
    check_logs! session, fn ->
      Client.current_url!(session)
    end
  end

  def current_path!(session) do
    check_logs! session, fn ->
      Client.current_path!(session)
    end
  end

  @doc """
  Gets the selected value of the element.

  For Checkboxes and Radio buttons it returns the selected option.
  For options selects it returns the selected option
  """
  def selected(element) do
    check_logs! element, fn ->
      Client.selected(element)
    end
  end

  @doc """
  Checks if the element is being displayed.

  This is based on what is available in phantom and doesn't match the current
  specification.
  """
  def displayed(element) do
    check_logs!(element, fn ->
      Client.displayed(element)
    end)
  end

  def displayed!(element) do
    check_logs! element, fn ->
      case displayed(element) do
        {:ok, value} ->
          value

        {:error, :stale_reference_error} ->
          raise Wallaby.StaleReferenceException
      end
    end
  end

  @doc """
  Gets the size of a element.

  This is non-standard and only works in Phantom.
  """
  def size(element) do
    check_logs! element, fn ->
      Client.size(element)
    end
  end

  @doc """
  Gets the height, width, x, and y position of an Element.

  This is based on the standard but currently is un-supported by Phantom.
  """
  def rect(element) do
    check_logs! element, fn ->
      Client.rect(element)
    end
  end

  @doc """
  Takes a screenshot.
  """
  def take_screenshot(session) do
    check_logs! session, fn ->
      Client.take_screenshot(session)
    end
  end

  def cookies(session) do
    check_logs! session, fn ->
      Client.cookies(session)
    end
  end

  def set_cookies(session, key, value) do
    check_logs! session, fn ->
      Client.set_cookie(session, key, value)
    end
  end


  @doc """
  Sets the size of the window.
  """
  def set_window_size(session, width, height) do
    check_logs! session, fn ->
      handle = window_handle(session)
      Client.set_window_size(session, handle, width, height)
    end
  end

  @doc """
  Gets the size of the window
  """
  def get_window_size(session) do
    check_logs! session, fn ->
      handle = window_handle(session)
      Client.get_window_size(session, handle)
    end
  end

  @doc """
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  def execute_script(session, script, arguments \\ []) do
    check_logs! session, fn ->
      Client.execute_script(session, script, arguments)
    end
  end

  @doc """
  Sends a list of key strokes to active element
  """
  def send_keys(parent, keys) when is_list(keys) do
    check_logs! parent, fn ->
      Client.send_keys(parent, keys)
    end
  end

  @doc """
  Retrieves logs from the browser
  """
  def log(session) do
    Client.log(session)
  end

  @doc """
  Retrieves the current page source from session
  """
  def page_source(session) do
    check_logs! session, fn ->
      Client.page_source(session)
    end
  end

  @doc """
  Accept all JavaScript dialogs
  """
  def accept_dialogs(session) do
    script = """
    var page = this;
    page.onAlert = function(msg) {}
    page.onConfirm = function(msg) { return true; }
    page.onPrompt = function(msg, defaultVal) { return defaultVal; }
    return "ok";
    """
    {:ok, "ok"} = execute_phantom_script(session, script)
  end

  @doc """
  Dismiss all JavaScript dialogs
  """
  def dismiss_dialogs(session) do
    script = """
    var page = this;
    page.onAlert = function(msg) {}
    page.onConfirm = function(msg) { return false; }
    page.onPrompt = function(msg, defaultVal) { return null; }
    return "ok";
    """
    {:ok, "ok"} = execute_phantom_script(session, script)
  end

  @doc """
  Accept one alert triggered within `fun` and return the alert message.
  """
  def accept_alert(%Session{}=session, fun) do
    script = """
    var page = this;
    page.__onAlertDefault = page.onAlert;
    page.onAlert = function(msg) {
      page.__alertMessage = msg;
      page.onAlert = page.__onAlertDefault;
    }
    return "ok";
    """
    {:ok, "ok"} = execute_phantom_script(session, script)
    fun.(session)
    script = """
    var page = this;
    page.onAlert = page.__onAlertDefault;
    return ["ok", page.__alertMessage];
    """
    {:ok, ["ok", message]} = execute_phantom_script(session, script)
    message
  end

  @doc """
  Accept one confirm triggered within `fun` and return the confirm message.
  """
  def accept_confirm(%Session{}=session, fun) do
    handle_confirm(session, fun, true)
  end

  @doc """
  Dismiss one confirm triggered within `fun` and return the confirm message.
  """
  def dismiss_confirm(%Session{}=session, fun) do
    handle_confirm(session, fun, false)
  end

  defp handle_confirm(%Session{}=session, fun, return_value) do
    script = """
    var page = this, returnVal = arguments[0];
    page.__onConfirmDefault = page.onConfirm;
    page.onConfirm = function(msg) {
      page.__confirmMessage = msg;
      page.onConfirm = page.__onConfirmDefault;
      return returnVal;
    }
    return "ok";
    """
    {:ok, "ok"} = execute_phantom_script(session, script, [return_value])
    fun.(session)
    script = """
    var page = this;
    page.onConfirm = page.__onConfirmDefault;
    return ["ok", page.__confirmMessage];
    """
    {:ok, ["ok", message]} = execute_phantom_script(session, script)
    message
  end

  @doc """
  Accept one prompt triggered within `fun` with the specified `input_value`
  and return the confirm message.
  """
  def accept_prompt(%Session{}=session, input_value, fun) do
    handle_prompt(session, fun, input_value, true)
  end

  @doc """
  Dismiss one prompt triggered within `fun` and return the confirm message.
  """
  def dismiss_prompt(%Session{}=session, fun) do
    handle_prompt(session, fun, nil, false)
  end

  defp handle_prompt(%Session{}=session, fun, return_value, use_default) do
    script = """
    var page = this, returnVal = arguments[0], useDefault = arguments[1];
    page.__onPromptDefault = page.onPrompt;
    page.onPrompt = function(msg, defaultVal) {
      page.__promptMessage = msg;
      page.onPrompt = page.__onPromptDefault;
      if (useDefault) {
        return returnVal || defaultVal;
      } else {
        return returnVal;
      }
    }
    return "ok";
    """
    {:ok, "ok"} = execute_phantom_script(session, script, [return_value, use_default])
    fun.(session)
    script = """
    var page = this;
    page.onPrompt = page.__onPromptDefault;
    return ["ok", page.__promptMessage];
    """
    {:ok, ["ok", message]} = execute_phantom_script(session, script)
    message
  end

  defp window_handle(session) do
    check_logs! session, fn ->
      Client.window_handle(session)
    end
  end

  def check_logs!(session, fun) do
    return_value = fun.()

    {:ok, logs} = log(session)

    session.session_url
    |> LogStore.append_logs(logs)
    |> Logger.log

    return_value
  end

  defp execute_phantom_script(session, script, arguments \\ []) do
    check_logs! session, fn ->
      PhantomClient.execute_script(session, script, arguments)
    end
  end
end
