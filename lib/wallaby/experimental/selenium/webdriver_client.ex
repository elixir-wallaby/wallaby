defmodule Wallaby.Experimental.Selenium.WebdriverClient do
  @moduledoc false
  alias Wallaby.{Driver, Element, Query, Session}
  alias Wallaby.Helpers.KeyCodes
  import Wallaby.HTTPClient

  @type http_method :: :post | :get | :delete
  @type url :: String.t

  @web_element_identifier "element-6066-11e4-a52e-4f735466cecf"

  @doc """
  Create a session with the base url.
  """
  @spec create_session(String.t, map) :: {:ok, map}
  def create_session(base_url, capabilities) do
    params = %{desiredCapabilities: capabilities}

    request(:post, "#{base_url}session", params)
  end

  @doc """
  Deletes a session with the driver.
  """
  @spec delete_session(Session.t | Element.t) :: {:ok, map}
  def delete_session(session) do
    request(:delete, session.session_url, %{})
  end

  @doc """
  Finds an element on the page for a session. If an element is provided then
  the query will be scoped to within that element.
  """
  @spec find_elements(Session.t | Element.t, Query.compiled) :: {:ok, [Element.t]}
  def find_elements(parent, locator) do
    with {:ok, resp} <- request(:post, parent.url <> "/elements", to_params(locator)),
          {:ok, elements} <- Map.fetch(resp, "value"),
          elements <- Enum.map(elements || [], &(cast_as_element(parent, &1))),
      do: {:ok, elements}
  end

  @doc """
  Sets the value of an element.
  """
  @spec set_value(Element.t, String.t) :: {:ok, nil} | {:error, Driver.reason}
  def set_value(%Element{url: url}, value) do
    case request(:post, "#{url}/value", %{value: [value]}) do
      {:ok, resp} -> {:ok, Map.get(resp, "value")}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Clears the value in an element
  """
  @spec clear(Element.t) :: {:ok, nil} | {:error, Driver.reason}
  def clear(%Element{url: url}) do
    case request(:post, "#{url}/clear") do
      {:ok, resp} -> {:ok, Map.get(resp, "value")}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Invoked to accept one alert triggered within `open_dialog_fn` and return the alert message.
  """
  def accept_alert(session, fun) do
    fun.(session)
    with  {:ok, value} <- alert_text(session),
          {:ok, _r} <- request(:post, "#{session.url}/accept_alert"),
      do: value
  end

  @doc """
  Invoked to accept one alert triggered within `open_dialog_fn` and return the alert message.
  """
  def dismiss_alert(session, fun) do
    accept_alert(session, fun)
  end

  def accept_confirm(session, fun) do
    accept_alert(session, fun)
  end

  def dismiss_confirm(session, fun) do
    fun.(session)
    with  {:ok, value} <- alert_text(session),
          {:ok, _r} <- request(:post, "#{session.url}/dismiss_alert"),
      do: value
  end

  def accept_prompt(session, input, fun) when is_nil(input) do
    fun.(session)
    with  {:ok, value} <- alert_text(session),
          {:ok, _r} <- request(:post, "#{session.url}/accept_alert"),
      do: value
  end

  def accept_prompt(session, input, fun) do
    fun.(session)
    with  {:ok, _r} <- request(:post, "#{session.url}/alert_text", %{text: input}),
          {:ok, value} <- alert_text(session),
          {:ok, _r} <- request(:post, "#{session.url}/accept_alert"),
      do: value
  end

  def dismiss_prompt(session, fun) do
    dismiss_confirm(session, fun)
  end

  @doc """
  Clicks an element
  """
  @spec click(Element.t) :: {:ok, map}
  def click(%Element{url: url}) do
    with  {:ok, resp} <- request(:post, "#{url}/click"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Gets the text for an element
  """
  @spec text(Element.t) :: {:ok, String.t}
  def text(element) do
    with  {:ok, resp} <- request(:get, "#{element.url}/text"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Gets the title of the current page.
  """
  @spec page_title(Session.t) :: {:ok, String.t}
  def page_title(session) do
    with  {:ok, resp} <- request(:get, "#{session.url}/title"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Gets the value of an elements attribute
  """
  @spec attribute(Element.t, String.t) :: {:ok, String.t}
  def attribute(element, name) do
    with {:ok, resp}  <- request(:get, "#{element.url}/attribute/#{name}"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Visit a specific page.
  """
  @spec visit(Session.t, String.t) :: :ok
  def visit(session, path) do
    with {:ok, resp} <- request(:post, "#{session.url}/url", %{url: path}),
          {:ok, _} <- Map.fetch(resp, "value"),
      do: :ok
  end

  @doc """
  Gets the current url.
  """
  @spec current_url(Session.t) :: {:ok, String.t} | {:error, any()}
  def current_url(session) do
    with  {:ok, resp} <- request(:get, "#{session.url}/url"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Gets the current path or nil.
  """
  @spec current_path(Session.t) :: {:ok, String.t} | {:error, any()}
  def current_path(session) do
    with {:ok, url} <- current_url(session),
         uri <- URI.parse(url),
         {:ok, path} <- Map.fetch(uri, :path),
      do: {:ok, path}
  end

  @doc """
  Gets the selected value of the element.

  For Checkboxes and Radio buttons it returns the selected option.
  For options selects it returns the selected option
  """
  @spec selected(Element.t) :: {:ok, boolean} | {:error, :stale_reference}
  def selected(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/selected"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Checks if the element is being displayed.

  This is based on what is available in phantom and doesn't match the current
  specification.
  """
  @spec displayed(Element.t) :: {:ok, boolean} | {:error, :stale_reference}
  def displayed(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/displayed"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Gets the size of a element.

  This is non-standard and only works in Phantom.
  """
  @spec size(Element.t) :: {:ok, any}
  def size(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/size"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Gets the height, width, x, and y position of an Element.

  This is based on the standard but currently is un-supported by Phantom.
  """
  @spec rect(Element.t) :: {:ok, any}
  def rect(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/rect"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Takes a screenshot.
  """
  @spec take_screenshot(Session.t | Element.t) :: binary
  def take_screenshot(session) do
    with {:ok, resp}   <- request(:get, "#{session.session_url}/screenshot"),
          {:ok, value}  <- Map.fetch(resp, "value"),
          decoded_value <- :base64.decode(value),
      do: decoded_value
  end

  @doc """
  Gets the cookies for a session.
  """
  @spec cookies(Session.t) :: {:ok, [map]}
  def cookies(session) do
    with {:ok, resp}  <- request(:get, "#{session.url}/cookie"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Sets a cookie for the session.
  """
  @spec set_cookie(Session.t, String.t, String.t) :: {:ok, []}
  def set_cookie(session, key, value) do
      with {:ok, resp}  <- request(:post, "#{session.url}/cookie", %{cookie: %{name: key, value: value}}),
           {:ok, value} <- Map.fetch(resp, "value"),
       do: {:ok, value}
  end

  @doc """
  Sets the size of the window.
  """
  @spec set_window_size(Session.t, non_neg_integer, non_neg_integer) :: {:ok, map}
  @spec set_window_size(Session.t, String.t, non_neg_integer, non_neg_integer) :: {:ok, map}

  def set_window_size(session, width, height) do
    with {:ok, resp} <- request(:post, "#{session.url}/window/rect", %{width: width, height: height}),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end
  def set_window_size(session, window_handle, width, height) do
    with {:ok, resp} <- request(:post, "#{session.url}/window/#{window_handle}/size", %{width: width, height: height}),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Gets the size of the window
  """
  @spec get_window_size(Session.t) :: {:ok, map}
  @spec get_window_size(Session.t, String.t) :: {:ok, map}

  def get_window_size(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/window/rect"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end
  def get_window_size(session, window_handle) do
    with {:ok, resp} <- request(:get, "#{session.url}/window/#{window_handle}/size"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  @spec execute_script(Session.t | Element.t, String.t, Keyword.t) :: {:ok, any}
  def execute_script(session, script, arguments \\ []) do
    with {:ok, resp} <- request(:post, "#{session.session_url}/execute", %{script: script, args: arguments}),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Sends a list of key strokes to active element
  """
  @spec send_keys(Session.t, [String.t | atom]) :: {:ok, nil}
  def send_keys(%Session{} = session, keys) when is_list(keys) do
    with {:ok, resp} <- request(:post, "#{session.session_url}/keys", KeyCodes.json(keys), encode_json: false),
          {:ok, value} <- Map.fetch(resp, "value"),
    do: {:ok, value}
  end
  def send_keys(parent, keys) when is_list(keys) do
    with {:ok, resp} <- request(:post, "#{parent.url}/value", KeyCodes.json(keys), encode_json: false),
          {:ok, value} <- Map.fetch(resp, "value"),
    do: {:ok, value}
  end

  @doc """
  Retrieves logs from the browser
  """
  @spec log(Session.t | Element.t) :: {:ok, [map]}
  def log(session) do
    with {:ok, resp} <- request(:post, "#{session.session_url}/log", %{type: "browser"}),
         {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Retrieves the current page source from session
  """
  @spec page_source(Session.t) :: {:ok, String.t}
  def page_source(session) do
    with  {:ok, resp} <- request(:get, "#{session.url}/source"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  def window_handles(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/window_handles"),
         {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

  @doc """
  Retrieves the window handle for from session
  """
  @spec window_handle(Session.t) :: String.t
  def window_handle(session) do
    with  {:ok, resp} <- request(:get, "#{session.url}/window_handle"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: value
  end

  @spec cast_as_element(Session.t | Element.t, map) :: Element.t
  defp cast_as_element(parent, %{"ELEMENT" => id}) do
    cast_as_element(parent, %{@web_element_identifier => id})
  end
  defp cast_as_element(parent, %{@web_element_identifier => id}) do
    %Wallaby.Element{
      id: id,
      session_url: parent.session_url,
      url: parent.session_url <> "/element/#{id}",
      parent: parent,
      driver: parent.driver,
    }
  end

  # Retrieves the text from an alert, prompt or confirm.
  @spec alert_text(Session.t) :: {:ok, String.t}
  defp alert_text(session) do
    with  {:ok, resp} <- request(:get, "#{session.url}/alert_text"),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end

end
