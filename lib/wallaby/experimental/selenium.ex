defmodule Wallaby.Experimental.Selenium do
  @moduledoc """
  The Selenium driver uses [Selenium Server](https://github.com/SeleniumHQ/selenium) to power many types of browsers (Chrome, Firefox, Edge, etc).

  ## Usage

  Start a Wallaby Session using this driver with the following command:

  ```
  {:ok, session} = Wallaby.start_session()
  ```

  ## Configuration

  ### Capabilities

  These capabilities will override the default capabilities.

  ```
  config :wallaby,
    selenium: [
      capabilities: %{
        # something
      }
    ]
  ```

  ## Default Capabilities

  By default, Selenium will use the following capabilities

  You can read more about capabilities in the [JSON Wire Protocol](https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#capabilities-json-object) documentation.

  ```elixir
  %{
    javascriptEnabled: true,
    browserName: "firefox",
    "moz:firefoxOptions": %{
      args: ["-headless"]
    }
  }
  ```

  ## Notes

  - Requires [selenium-server-standalone](https://www.seleniumhq.org/download/) to be running on port 4444. Wallaby does _not_ manage the start/stop of the Selenium server.
  - Requires [GeckoDriver](https://github.com/mozilla/geckodriver) to be installed in your path when using [Firefox](https://www.mozilla.org/en-US/firefox/new/). Firefox is used by default.
  """

  use Supervisor

  @behaviour Wallaby.Driver

  alias Wallaby.{Driver, Element, Session}
  alias Wallaby.Experimental.Selenium.WebdriverClient

  @typedoc """
  Options to pass to Wallaby.start_session/1

  ```elixir
  Wallaby.start_session(
    remote_url: "http://selenium_url",
    capabilities: %{browserName: "firefox"},
    create_session_fn: fn url, capabilities ->
      WebdriverClient.create_session(url, capabilities)
    end
  )
  ```
  """
  @type start_session_opts ::
          {:remote_url, String.t()}
          | {:capabilities, map}
          | {:create_session_fn, (String.t(), map -> {:ok, %{}})}

  @typedoc false
  @type end_session_opts :: {:end_session_fn, (Session.t() -> any)}

  @doc false
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc false
  def init(:ok) do
    supervise([], strategy: :one_for_one)
  end

  @doc false
  def validate do
    :ok
  end

  @doc false
  @spec start_session([start_session_opts]) :: Wallaby.Driver.on_start_session() | no_return
  def start_session(opts \\ []) do
    base_url = Keyword.get(opts, :remote_url, "http://localhost:4444/wd/hub/")
    create_session_fn = Keyword.get(opts, :create_session_fn, &WebdriverClient.create_session/2)

    capabilities = Keyword.get(opts, :capabilities, capabilities_from_config())

    with {:ok, response} <- create_session_fn.(base_url, capabilities) do
      id = response["sessionId"]

      session = %Wallaby.Session{
        session_url: base_url <> "session/#{id}",
        url: base_url <> "session/#{id}",
        id: id,
        driver: __MODULE__
      }

      if window_size = Keyword.get(opts, :window_size),
        do: {:ok, _} = set_window_size(session, window_size[:width], window_size[:height])

      {:ok, session}
    end
  end

  defp capabilities_from_config() do
    :wallaby
    |> Application.get_env(:selenium, [])
    |> Keyword.get(:capabilities, default_capabilities())
  end

  @doc false
  @spec end_session(Session.t(), [end_session_opts]) :: :ok
  def end_session(session, opts \\ []) do
    end_session_fn = Keyword.get(opts, :end_session_fn, &WebdriverClient.delete_session/1)

    end_session_fn.(session)
    :ok
  end

  @doc false
  def blank_page?(session) do
    case current_url(session) do
      {:ok, url} ->
        url == "about:blank"

      _ ->
        false
    end
  end

  @doc false
  defdelegate window_handle(session), to: WebdriverClient
  @doc false
  defdelegate window_handles(session), to: WebdriverClient
  @doc false
  defdelegate focus_window(session, window_handle), to: WebdriverClient
  @doc false
  defdelegate close_window(session), to: WebdriverClient
  @doc false
  defdelegate get_window_size(session), to: WebdriverClient
  @doc false
  defdelegate set_window_size(session, width, height), to: WebdriverClient
  @doc false
  defdelegate get_window_position(session), to: WebdriverClient
  @doc false
  defdelegate set_window_position(session, x, y), to: WebdriverClient
  @doc false
  defdelegate maximize_window(session), to: WebdriverClient

  @doc false
  defdelegate focus_frame(session, frame), to: WebdriverClient
  @doc false
  defdelegate focus_parent_frame(session), to: WebdriverClient

  @doc false
  defdelegate accept_alert(session, fun), to: WebdriverClient
  @doc false
  defdelegate dismiss_alert(session, fun), to: WebdriverClient
  @doc false
  defdelegate accept_confirm(session, fun), to: WebdriverClient
  @doc false
  defdelegate dismiss_confirm(session, fun), to: WebdriverClient
  @doc false
  defdelegate accept_prompt(session, input, fun), to: WebdriverClient
  @doc false
  defdelegate dismiss_prompt(session, fun), to: WebdriverClient

  @doc false
  defdelegate take_screenshot(session_or_element), to: WebdriverClient

  @doc false
  def cookies(%Session{} = session) do
    WebdriverClient.cookies(session)
  end

  @doc false
  def current_path(%Session{} = session) do
    with {:ok, url} <- WebdriverClient.current_url(session),
         uri <- URI.parse(url),
         {:ok, path} <- Map.fetch(uri, :path),
         do: {:ok, path}
  end

  @doc false
  def current_url(%Session{} = session) do
    WebdriverClient.current_url(session)
  end

  @doc false
  def page_source(%Session{} = session) do
    WebdriverClient.page_source(session)
  end

  @doc false
  def page_title(%Session{} = session) do
    WebdriverClient.page_title(session)
  end

  @doc false
  def set_cookie(%Session{} = session, key, value) do
    WebdriverClient.set_cookie(session, key, value)
  end

  @doc false
  def visit(%Session{} = session, path) do
    WebdriverClient.visit(session, path)
  end

  @doc false
  def attribute(%Element{} = element, name) do
    WebdriverClient.attribute(element, name)
  end

  @doc false
  @spec clear(Element.t()) :: {:ok, nil} | {:error, Driver.reason()}
  def clear(%Element{} = element) do
    WebdriverClient.clear(element)
  end

  @doc false
  def click(%Element{} = element) do
    WebdriverClient.click(element)
  end

  @doc false
  def click(parent, button) do
    WebdriverClient.click(parent, button)
  end

  @doc false
  def button_down(parent, button) do
    WebdriverClient.button_down(parent, button)
  end

  @doc false
  def button_up(parent, button) do
    WebdriverClient.button_up(parent, button)
  end

  @doc false
  def double_click(parent) do
    WebdriverClient.double_click(parent)
  end

  @doc false
  def hover(%Element{} = element) do
    WebdriverClient.move_mouse_to(nil, element)
  end

  @doc false
  def move_mouse_by(session, x_offset, y_offset) do
    WebdriverClient.move_mouse_to(session, nil, x_offset, y_offset)
  end

  def touch_down(session, element, x_or_offset, y_or_offset) do
    WebdriverClient.touch_down(session, element, x_or_offset, y_or_offset)
  end

  def touch_up(parent) do
    WebdriverClient.touch_up(parent)
  end

  def tap(element) do
    WebdriverClient.tap(element)
  end

  def touch_move(parent, x, y) do
    WebdriverClient.touch_move(parent, x, y)
  end

  def touch_scroll(parent, x_offset, y_offset) do
    WebdriverClient.touch_scroll(parent, x_offset, y_offset)
  end

  @doc false
  def displayed(%Element{} = element) do
    WebdriverClient.displayed(element)
  end

  @doc false
  def selected(%Element{} = element) do
    WebdriverClient.selected(element)
  end

  @doc false
  @spec set_value(Element.t(), String.t()) :: {:ok, nil} | {:error, Driver.reason()}
  def set_value(%Element{} = element, value) do
    WebdriverClient.set_value(element, value)
  end

  @doc false
  def text(%Element{} = element) do
    WebdriverClient.text(element)
  end

  @doc false
  def find_elements(parent, compiled_query) do
    WebdriverClient.find_elements(parent, compiled_query)
  end

  @doc false
  def execute_script(parent, script, arguments \\ []) do
    WebdriverClient.execute_script(parent, script, arguments)
  end

  @doc false
  def execute_script_async(parent, script, arguments \\ []) do
    WebdriverClient.execute_script_async(parent, script, arguments)
  end

  @doc false
  def send_keys(parent, keys) do
    WebdriverClient.send_keys(parent, keys)
  end

  def element_size(element) do
    WebdriverClient.element_size(element)
  end

  def element_location(element) do
    WebdriverClient.element_location(element)
  end

  defp default_capabilities do
    %{
      javascriptEnabled: true,
      browserName: "firefox",
      "moz:firefoxOptions": %{
        args: ["-headless"]
      }
    }
  end
end
