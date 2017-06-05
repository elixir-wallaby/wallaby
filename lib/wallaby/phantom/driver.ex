defmodule Wallaby.Phantom.Driver do
  @moduledoc false

  alias Wallaby.{Driver, Element, Session}
  alias Wallaby.Phantom.Logger
  alias Wallaby.Phantom.LogStore

  @type method :: :post | :get | :delete
  @type url :: String.t
  @type query :: String.t
  @type params :: %{using: String.t, value: query}
  @type locator :: Session.t | Element.t

  @type response_errors ::
    {:error, :invalid_selector} |
    {:error, :stale_reference}

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

    {:ok, response} =  create_session(base_url, capabilities)
    id = response["sessionId"]

    session = %Wallaby.Session{
      session_url: base_url <> "session/#{id}",
      url: base_url <> "session/#{id}",
      id: id,
      server: server,
      driver: Wallaby.Phantom
    }

    {:ok, session}
  end

  # Create a session with the base url.
  @doc false
  @spec create_session(String.t, map) :: {:ok, map}
  def create_session(base_url, capabilities) do
    params = %{desiredCapabilities: capabilities}

    request(:post, "#{base_url}session", params)
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

  def find_elements(parent, locator) do
    check_logs! parent, fn ->
      with {:ok, resp} <- request(:post, parent.url <> "/elements", to_params(locator)),
           {:ok, elements} <- Map.fetch(resp, "value"),
           elements <- Enum.map(elements, &(cast_as_element(parent, &1))),
        do: {:ok, elements}
    end
  end

  @doc """
  Sets the value of an element.
  """
  def set_value(%Element{url: url}=element, value) do
     check_logs! element, fn ->
      with  {:ok, resp} <- request(:post, "#{url}/value", %{value: [value]}),
            {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end
  end

  @doc """
  Clears the value in an element
  """
  # @spec clear(Locator.t, query) :: t
  def clear(%Element{url: url}=element) do
    check_logs! element, fn ->
      with {:ok, resp} <- request(:post, "#{url}/clear"),
           {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end
  end

  @doc """
  Clicks an element
  """
  def click(%Element{url: url}=element) do
    check_logs! element, fn ->
      with  {:ok, resp} <- request(:post, "#{url}/click"),
            {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end
  end

  @doc """
  Gets the text for an element
  """
  def text(element) do
    check_logs! element, fn ->
      with  {:ok, resp} <- request(:get, "#{element.url}/text"),
            {:ok, value} <- Map.fetch(resp, "value"),
      	do: {:ok, value}
    end
  end

  @doc """
  Gets the title of the current page.
  """
  def page_title(session) do
    check_logs! session, fn ->
      with  {:ok, resp} <- request(:get, "#{session.url}/title"),
      			{:ok, value} <- Map.fetch(resp, "value"),
  			do: {:ok, value}
    end
  end

  @doc """
  Gets the value of an elements attribute
  """
  def attribute(element, name) do
    check_logs! element, fn ->
      with {:ok, resp}  <- request(:get, "#{element.url}/attribute/#{name}"),
           {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end
  end

  @doc """
  Visits a specific page.
  """
  @spec visit(Session.t, String.t) :: :ok
  def visit(session, path) do
    check_logs! session, fn ->
      with {:ok, _} <- request(:post, "#{session.url}/url", %{url: path}),
      do: :ok
    end
  end

  @doc """
  Gets the current url.
  """
  def current_url(session) do
    check_logs! session, fn ->
      with  {:ok, resp} <- request(:get, "#{session.url}/url"),
            {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end
  end

  def current_url!(session) do
    check_logs! session, fn ->
      request!(:get, "#{session.url}/url")
      |> Map.get("value")
    end
  end

  def current_path!(session) do
    check_logs! session, fn ->
      session
      |> current_url!
      |> URI.parse
      |> Map.get(:path)
    end
  end

  @doc """
  Gets the selected value of the element.

  For Checkboxes and Radio buttons it returns the selected option.
  For options selects it returns the selected option
  """
  def selected(element) do
    check_logs! element, fn ->
      with {:ok, resp} <- request(:get, "#{element.url}/selected"),
           {:ok, value} <- Map.fetch(resp, "value"),
       do: {:ok, value}
    end
  end

  @doc """
  Checks if the element is being displayed.

  This is based on what is available in phantom and doesn't match the current
  specification.
  """
  def displayed(element) do
    check_logs!(element, fn ->
      with {:ok, resp} <- request(:get, "#{element.url}/displayed"),
      		 {:ok, value} <- Map.fetch(resp, "value"),
				do: {:ok, value}
    end)
  end

  def displayed!(element) do
    check_logs! element, fn ->
      case displayed(element) do
        {:ok, value} ->
          value

        {:error, :stale_reference} ->
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
      with {:ok, resp} <- request(:get, "#{element.url}/size"),
      		 {:ok, value} <- Map.fetch(resp, "value"),
				do: {:ok, value}
    end
  end

  @doc """
  Gets the height, width, x, and y position of an Element.

  This is based on the standard but currently is un-supported by Phantom.
  """
  def rect(element) do
    check_logs! element, fn ->
      with {:ok, resp} <- request(:get, "#{element.url}/rect"),
           {:ok, value} <- Map.fetch(resp, "value"),
       do: {:ok, value}
    end
  end

  @doc """
  Takes a screenshot.
  """
  def take_screenshot(session) do
    check_logs! session, fn ->
      with {:ok, resp}   <- request(:get, "#{session.url}/screenshot"),
           {:ok, value}  <- Map.fetch(resp, "value"),
           decoded_value <- :base64.decode(value),
        do: decoded_value
    end
  end

  def cookies(session) do
    check_logs! session, fn ->
      with {:ok, resp}  <- request(:get, "#{session.url}/cookie"),
           {:ok, value} <- Map.fetch(resp, "value"),
       do: {:ok, value}
    end
  end

  def set_cookies(session, key, value) do
    check_logs! session, fn ->
      with {:ok, resp}  <- request(:post, "#{session.url}/cookie", %{cookie: %{name: key, value: value}}),
           {:ok, value} <- Map.fetch(resp, "value"),
       do: {:ok, value}
    end
  end


  @doc """
  Sets the size of the window.
  """
  def set_window_size(session, width, height) do
    check_logs! session, fn ->
      with {:ok, resp} <- request(:post, "#{session.url}/window/#{window_handle(session)}/size", %{width: width, height: height}),
           {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end
  end

  @doc """
  Gets the size of the window
  """
  def get_window_size(session) do
    check_logs! session, fn ->
      with {:ok, resp} <- request(:get, "#{session.url}/window/#{window_handle(session)}/size"),
           {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end
  end

  @type execute_script_opts :: {:check_logs, boolean}

  @doc """
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  @spec execute_script(Session.t, String.t, [any], [execute_script_opts]) ::
    {:ok, any} | {:error, Driver.reason}
  def execute_script(session, script, arguments \\ [], opts \\ []) do
    check_logs = Keyword.get(opts, :check_logs, true)
    request_fn = fn ->
      with {:ok, resp} <- request(:post, "#{session.session_url}/execute", %{script: script, args: arguments}),
           {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end

    if check_logs do
      check_logs! session, request_fn
    else
      request_fn.()
    end
  end

  @doc """
  Sends a list of key strokes to active element
  """
  def send_keys(%Session{}=session, keys) when is_list(keys) do
    check_logs! session, fn ->
      with {:ok, resp} <- request(:post, "#{session.session_url}/keys", Wallaby.Helpers.KeyCodes.json(keys), encode_json: false),
           {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
    end
  end
  def send_keys(parent, keys) when is_list(keys) do
    check_logs! parent, fn ->
      with {:ok, resp} <- request(:post, "#{parent.url}/value", Wallaby.Helpers.KeyCodes.json(keys), encode_json: false),
           {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
    end
  end

  @doc """
  Retrieves logs from the browser
  """
  def log(session) do
    with {:ok, resp} <- request(:post, "#{session.session_url}/log", %{type: "browser"}),
         {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Retrives the current page source from session
  """
  def page_source(session) do
    check_logs! session, fn ->
      with  {:ok, resp} <- request(:get, "#{session.url}/source"),
            {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
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
      with  {:ok, resp} <- request(:get, "#{session.url}/window_handle"),
            {:ok, value} <- Map.fetch(resp, "value"),
        do: value
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

    {:ok, logs} = log(session)

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

  defp request!(method, url) do
    make_request!(method, url, "")
  end

  defp make_request(method, url, body) do
    HTTPoison.request(method, url, body, headers(), request_opts())
    |> handle_response
  end

  defp handle_response({:error, %HTTPoison.Error{}} = response), do: response
  defp handle_response({:ok, %HTTPoison.Response{status_code: 204}}), do: {:ok, %{"value" => %{}}}
  defp handle_response({:ok, %HTTPoison.Response{body: body}}) do
    with {:ok, decoded} <- Poison.decode(body),
         {:ok, validated} <- check_for_response_errors(decoded),
      do: {:ok, validated}
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

  @spec check_for_response_errors(map) :: {:ok, map} | response_errors
  def check_for_response_errors(response) do
    case Map.get(response, "value") do
      %{"class" => "org.openqa.selenium.StaleElementReferenceException"} ->
        {:error, :stale_reference}
      %{"class" => "org.openqa.selenium.InvalidSelectorException"} ->
        {:error, :invalid_selector}
      %{"class" => "org.openqa.selenium.InvalidElementStateException"} ->
        {:error, :invalid_selector}
      _ ->
        {:ok, response}
    end
  end

  def request_opts do
    Application.get_env(:wallaby, :hackney_options, [])
  end

  def headers do
    [{"Accept", "application/json"},
      {"Content-Type", "application/json"}]
  end

  defp cast_as_element(parent, %{"ELEMENT" => id}) do
    %Wallaby.Element{
      id: id,
      session_url: parent.session_url,
      url: parent.session_url <> "/element/#{id}",
      parent: parent,
      driver: parent.driver,
    }
  end

  defp execute_phantom_script(session, script, arguments \\ []) do
    check_logs! session, fn ->
      with {:ok, resp} <- request(:post, "#{session.session_url}/phantom/execute", %{script: script, args: arguments}),
           {:ok, value} <- Map.fetch(resp, "value"),
        do: {:ok, value}
    end
  end
end
