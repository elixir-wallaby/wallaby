defmodule Wallaby.WebdriverClient do
  @moduledoc false
  # Client implementation for the WebDriver Wire Protocol
  # documented on https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
  alias Wallaby.{Driver, Element, Query, Session}
  alias Wallaby.Helpers.KeyCodes
  import Wallaby.HTTPClient

  @type http_method :: :post | :get | :delete
  @type url :: String.t()
  @type parent ::
          Element.t()
          | Session.t()

  @web_element_identifier "element-6066-11e4-a52e-4f735466cecf"

  @doc """
  Create a session with the base url.
  """
  @spec create_session(String.t(), map) :: {:ok, map}
  def create_session(base_url, capabilities) do
    params = %{desiredCapabilities: capabilities}

    request(:post, "#{base_url}session", params)
  end

  @doc """
  Deletes a session with the driver.
  """
  @spec delete_session(Session.t() | Element.t()) :: {:ok, map}
  def delete_session(session) do
    request(:delete, session.session_url, %{})
  rescue
    _ -> {:ok, %{}}
  end

  @doc """
  Finds an element on the page for a session. If an element is provided then
  the query will be scoped to within that element.
  """
  @spec find_elements(Session.t() | Element.t(), Query.compiled()) :: {:ok, [Element.t()]}
  def find_elements(parent, locator) do
    with {:ok, resp} <- request(:post, parent.url <> "/elements", to_params(locator)),
         {:ok, elements} <- Map.fetch(resp, "value"),
         elements <- Enum.map(elements || [], &cast_as_element(parent, &1)),
         do: {:ok, elements}
  end

  @doc """
  Sets the value of an element.
  """
  @spec set_value(Element.t(), String.t()) :: {:ok, nil} | {:error, Driver.reason()}
  def set_value(%Element{url: url}, value) do
    case request(:post, "#{url}/value", %{value: [value]}) do
      {:ok, resp} -> {:ok, Map.get(resp, "value")}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Clears the value in an element
  """
  @spec clear(Element.t()) :: {:ok, nil} | {:error, Driver.reason()}
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

    with {:ok, value} <- alert_text(session),
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

    with {:ok, value} <- alert_text(session),
         {:ok, _r} <- request(:post, "#{session.url}/dismiss_alert"),
         do: value
  end

  def accept_prompt(session, input, fun) when is_nil(input) do
    fun.(session)

    with {:ok, value} <- alert_text(session),
         {:ok, _r} <- request(:post, "#{session.url}/accept_alert"),
         do: value
  end

  def accept_prompt(session, input, fun) do
    fun.(session)

    with {:ok, _r} <- request(:post, "#{session.url}/alert_text", %{text: input}),
         {:ok, value} <- alert_text(session),
         {:ok, _r} <- request(:post, "#{session.url}/accept_alert"),
         do: value
  end

  def dismiss_prompt(session, fun) do
    dismiss_confirm(session, fun)
  end

  @doc """
  Clicks an element.
  """
  @spec click(Element.t()) :: {:ok, map}
  def click(%Element{url: url}) do
    with {:ok, resp} <- request(:post, "#{url}/click"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Clicks given mouse button on the current cursor position.
  """
  # Doesn't work for Firefox with middle and right mouse button
  @spec click(parent, atom) :: {:ok, map}
  def click(parent, button) when button in [:left, :middle, :right] do
    button_mapping = %{left: 0, middle: 1, right: 2}

    with {:ok, resp} <-
           request(:post, "#{parent.session_url}/click", %{button: button_mapping[button]}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Double-clicks left mouse button at the current mouse coordinates.
  """
  @spec double_click(parent) :: {:ok, map}
  def double_click(parent) do
    with {:ok, resp} <-
           request(:post, "#{parent.session_url}/doubleclick"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Clicks and holds the given mouse button at the current mouse coordinates.
  """
  # Doesn't work for Firefox with middle and right mouse button.
  @spec button_down(parent, atom) :: {:ok, map}
  def button_down(parent, button) when button in [:left, :middle, :right] do
    button_mapping = %{left: 0, middle: 1, right: 2}

    with {:ok, resp} <-
           request(:post, "#{parent.session_url}/buttondown", %{button: button_mapping[button]}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Releases given previously held mouse button.
  """
  # Doesn't work for Firefox with middle and right mouse button.
  @spec button_up(parent, atom) :: {:ok, map}
  def button_up(parent, button) when button in [:left, :middle, :right] do
    button_mapping = %{left: 0, middle: 1, right: 2}

    with {:ok, resp} <-
           request(:post, "#{parent.session_url}/buttonup", %{button: button_mapping[button]}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Move the mouse by an offset of the specified element.
  If no element is specified, the move is relative to the current mouse cursor.
  If an element is provided but no offset, the mouse will be moved to the center of the element.

  Gets keyword list with element, xoffset and yoffset specified as an argument.
  """
  @spec move_mouse_to(parent | nil, Element.t() | nil, integer | nil, integer | nil) :: {:ok, map}
  def move_mouse_to(session, element, x_offset \\ nil, y_offset \\ nil) do
    params =
      %{element: element, xoffset: x_offset, yoffset: y_offset}
      |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
      |> Enum.into(%{})

    params =
      if Map.has_key?(params, :element) do
        Map.put(params, :element, params[:element].id)
      else
        params
      end

    session_url =
      if is_nil(element) do
        session.session_url
      else
        element.session_url
      end

    with {:ok, resp} <-
           request(:post, "#{session_url}/moveto", params),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Touches the screen at the given position.
  """
  @spec touch_down(parent | nil, Element.t() | nil, integer, integer) :: {:ok, map}
  def touch_down(session, element, x_or_offset \\ 0, y_or_offset \\ 0) do
    session_url =
      if is_nil(element) do
        session.session_url
      else
        element.session_url
      end

    {x, y} =
      if is_nil(element) do
        {x_or_offset, y_or_offset}
      else
        {:ok, {x, y}} = element_location(element)
        {x + x_or_offset, y + y_or_offset}
      end

    with {:ok, resp} <-
           request(:post, "#{session_url}/touch/down", %{x: x, y: y}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Stops touching the screen.
  """
  @spec touch_up(parent) :: {:ok, map}
  def touch_up(parent) do
    # in fact x and y (in request params) can be any coordinates not greater than page size
    with {:ok, resp} <-
           request(:post, "#{parent.session_url}/touch/up", %{x: 0, y: 0}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Taps the element.
  """
  @spec tap(Element.t()) :: {:ok, map}
  def tap(element) do
    with {:ok, resp} <-
           request(:post, "#{element.session_url}/touch/click", %{element: element.id}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Moves the touch pointer (finger, stylus etc.) on the screen to the point determined by the given coordinates.
  """
  @spec touch_move(parent, non_neg_integer, non_neg_integer) :: {:ok, map}
  def touch_move(parent, x, y) do
    with {:ok, resp} <-
           request(:post, "#{parent.session_url}/touch/move", %{x: x, y: y}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Scroll on the screen from the given element by the given offset using touch events.
  """
  @spec touch_scroll(Element.t(), integer, integer) :: {:ok, map}
  def touch_scroll(element, x_offset, y_offset) do
    with {:ok, resp} <-
           request(:post, "#{element.session_url}/touch/scroll", %{
             element: element.id,
             xoffset: x_offset,
             yoffset: y_offset
           }),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Gets the text for an element.
  """
  @spec text(Element.t()) :: {:ok, String.t()}
  def text(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/text"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Gets the title of the current page.
  """
  @spec page_title(Session.t()) :: {:ok, String.t()}
  def page_title(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/title"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Gets the value of an elements attribute.
  """
  @spec attribute(Element.t(), String.t()) :: {:ok, String.t()}
  def attribute(element, name) do
    with {:ok, resp} <- request(:get, "#{element.url}/attribute/#{name}"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Visit a specific page.
  """
  @spec visit(Session.t(), String.t()) :: :ok
  def visit(session, path) do
    with {:ok, resp} <- request(:post, "#{session.url}/url", %{url: path}),
         {:ok, _} <- Map.fetch(resp, "value"),
         do: :ok
  end

  @doc """
  Gets the current url.
  """
  @spec current_url(Session.t()) :: {:ok, String.t()} | {:error, any()}
  def current_url(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/url"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Gets the current path or nil.
  """
  @spec current_path(Session.t()) :: {:ok, String.t()} | {:error, any()}
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
  @spec selected(Element.t()) :: {:ok, boolean} | {:error, :stale_reference}
  def selected(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/selected"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Checks if the element is being displayed.
  """
  @spec displayed(Element.t()) :: {:ok, boolean} | {:error, :stale_reference}
  def displayed(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/displayed"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Gets the size of a element.
  """
  @spec size(Element.t()) :: {:ok, any}
  def size(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/size"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Gets the height, width, x, and y position of an Element.
  """
  @spec rect(Element.t()) :: {:ok, any}
  def rect(element) do
    with {:ok, resp} <- request(:get, "#{element.url}/rect"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Takes a screenshot.
  """
  @spec take_screenshot(Session.t() | Element.t()) :: binary
  def take_screenshot(session) do
    with {:ok, resp} <- request(:get, "#{session.session_url}/screenshot"),
         {:ok, value} <- Map.fetch(resp, "value"),
         decoded_value <- :base64.decode(value),
         do: decoded_value
  end

  @doc """
  Gets the cookies for a session.
  """
  @spec cookies(Session.t()) :: {:ok, [map]}
  def cookies(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/cookie"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Sets a cookie for the session.
  """
  @spec set_cookie(Session.t(), String.t(), String.t()) :: {:ok, []}
  def set_cookie(session, key, value) do
    with {:ok, resp} <-
           request(:post, "#{session.url}/cookie", %{cookie: %{name: key, value: value}}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Sets the size of the window
  """
  @spec set_window_size(parent, non_neg_integer, non_neg_integer) :: {:ok, map}
  def set_window_size(session, width, height) do
    with {:ok, resp} <-
           request(:post, "#{session.url}/window/current/size", %{width: width, height: height}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Gets the size of the window
  """
  @spec get_window_size(parent) :: {:ok, map}
  def get_window_size(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/window/current/size"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Changes the position of the window
  """
  @spec set_window_position(parent, non_neg_integer, non_neg_integer) :: {:ok, map}
  def set_window_position(session, x_coordinate, y_coordinate) do
    with {:ok, resp} <-
           request(:post, "#{session.url}/window/current/position", %{
             x: x_coordinate,
             y: y_coordinate
           }),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Gets the position of the window
  """
  @spec get_window_position(parent) :: {:ok, map}
  def get_window_position(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/window/current/position"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Maximizes the window if not already maximized
  """
  @spec maximize_window(parent) :: {:ok, map}
  def maximize_window(session) do
    with {:ok, resp} <- request(:post, "#{session.url}/window/current/maximize"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Executes JavaScript synchronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  @spec execute_script(Session.t() | Element.t(), String.t(), Keyword.t()) :: {:ok, any}
  def execute_script(session, script, arguments \\ []) do
    with {:ok, resp} <-
           request(:post, "#{session.session_url}/execute", %{script: script, args: arguments}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Executes asynchronous JavaScript, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  @spec execute_script_async(Session.t() | Element.t(), String.t(), Keyword.t()) :: {:ok, any}
  def execute_script_async(session, script, arguments \\ []) do
    with {:ok, resp} <-
           request(:post, "#{session.session_url}/execute_async", %{
             script: script,
             args: arguments
           }),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Sends a list of key strokes to active element.
  """
  @spec send_keys(parent(), [String.t() | atom]) :: {:ok, any}
  def send_keys(%Session{} = session, keys) when is_list(keys) do
    with {:ok, resp} <-
           request(:post, "#{session.session_url}/keys", KeyCodes.json(keys), encode_json: false),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  def send_keys(%Element{} = element, keys) when is_list(keys) do
    with {:ok, resp} <-
           request(:post, "#{element.url}/value", KeyCodes.json(keys), encode_json: false),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Retrieves logs from the browser
  """
  @spec log(Session.t() | Element.t()) :: {:ok, [map]}
  def log(session) do
    with {:ok, resp} <- request(:post, "#{session.session_url}/log", %{type: "browser"}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Retrieves the current page source from session
  """
  @spec page_source(Session.t()) :: {:ok, String.t()}
  def page_source(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/source"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Retrieves the list of window handles of all windows (or tabs) available to the session
  """
  @spec window_handles(parent) :: {:ok, list(String.t())}
  def window_handles(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/window_handles"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Retrieves the window handle for the currently focused window (or tab) for the session
  """
  @spec window_handle(parent) :: {:ok, String.t()}
  def window_handle(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/window_handle"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Changes focus to another window (or tab)

  You may specify the the window by its server-assigned window handle
  or by the value of its name attribute.
  """
  @spec focus_window(parent, String.t()) :: {:ok, map}
  def focus_window(session, window_handle_or_name) do
    with {:ok, resp} <-
           request(:post, "#{session.url}/window", %{
             name: window_handle_or_name,
             handle: window_handle_or_name
           }),
         # In the Selenium WebDriver Protocol, the parameter is called name:
         #  https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidwindow
         # In the new W3C protocol, the parameter is called handle:
         #  https://w3c.github.io/webdriver/#switch-to-window
         # Browsers are starting to support only the new W3C protocol,
         # so we're adding `handle` as well to have it working until
         # we implement a separate client module for the new protocol.
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Closes the currently focused window (or tab)
  """
  @spec close_window(parent) :: {:ok, map}
  def close_window(session) do
    with {:ok, resp} <- request(:delete, "#{session.url}/window"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Changes focus to another frame

  You may specify the the frame by passing the frame Element, its index or id.
  When passed `nil`, the server should switch to the page's default (top level) frame.
  """
  @spec focus_frame(parent, String.t() | number | nil | Element.t()) :: {:ok, map}
  def focus_frame(session, %Element{} = frame_element) do
    with {:ok, resp} <-
           request(:post, "#{session.url}/frame", %{
             id: %{
               "ELEMENT" => frame_element.id,
               @web_element_identifier => frame_element.id
             }
           }),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  def focus_frame(session, frame) do
    with {:ok, resp} <- request(:post, "#{session.url}/frame", %{id: frame}),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Changes focus to parent frame
  """
  @spec focus_parent_frame(parent) :: {:ok, map}
  def focus_parent_frame(session) do
    with {:ok, resp} <- request(:post, "#{session.url}/frame/parent"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end

  @doc """
  Returns a tuple `{width, height}` with the size of the given element.
  """
  @spec element_size(Element.t()) :: {:ok, tuple}
  def element_size(element) do
    with {:ok, resp} <- request(:get, "#{element.session_url}/element/#{element.id}/size"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, {value["width"], value["height"]}}
  end

  @doc """
  Returns a tuple `{x, y}` with the coordinates of the top-left corner of given element.
  """
  @spec element_location(Element.t()) :: {:ok, tuple}
  def element_location(element) do
    with {:ok, resp} <- request(:get, "#{element.session_url}/element/#{element.id}/location"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, {value["x"], value["y"]}}
  end

  @spec cast_as_element(Session.t() | Element.t(), map) :: Element.t()
  defp cast_as_element(parent, %{"ELEMENT" => id}) do
    # In the Selenium WebDriver Protocol, the identifier is "ELEMENT":
    #  https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#webelement-json-object
    # In the new W3C protocol, the identifier is a specific constant:
    #  https://w3c.github.io/webdriver/#elements
    # Browsers are starting to support only the new W3C protocol,
    # so we're reading the constant as well to have it working until
    # we implement a separate client module for the new protocol.
    cast_as_element(parent, %{@web_element_identifier => id})
  end

  defp cast_as_element(parent, %{@web_element_identifier => id}) do
    %Wallaby.Element{
      id: id,
      session_url: parent.session_url,
      url: parent.session_url <> "/element/#{id}",
      parent: parent,
      driver: parent.driver
    }
  end

  # Retrieves the text from an alert, prompt or confirm.
  @spec alert_text(Session.t()) :: {:ok, String.t()}
  defp alert_text(session) do
    with {:ok, resp} <- request(:get, "#{session.url}/alert_text"),
         {:ok, value} <- Map.fetch(resp, "value"),
         do: {:ok, value}
  end
end
