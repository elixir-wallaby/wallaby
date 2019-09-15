defmodule Wallaby.Experimental.Chrome do
  @moduledoc """
  The Chrome driver uses [Chromedriver](https://sites.google.com/a/chromium.org/chromedriver/) to power Google Chrome and Chromium.

  ## Usage

  Start a Wallaby Session using this driver with the following command:

  ```
  {:ok, session} = Wallaby.start_session()
  ```

  ## Configuration

  ### Headless

  Chrome will run headlessly by default.
  You can disable this behaviour using the following configuration.

  This will override the default capabilities and capabilities set with application configuration.
  This will _not_ override capabilities passed in directly to `Wallaby.start_session/1`.

  ```
  config :wallaby,
    chromedriver: [
      headless: false
    ]
  ```

  ### Capabilities

  These capabilities will override the default capabilities.

  ```
  config :wallaby,
    chromedriver: [
      capabilities: %{
        # something
      }
    ]
  ```

  ### ChromeDriver binary

  If ChromeDriver is not available in your path, you can specify it's location.

  ```
  config :wallaby,
    chromedriver: [
      path: "path/to/chrome"
    ]
  ```

  ### Chrome binary

  This configures which instance of Google Chrome to use.

  This will override the default capabilities and capabilities set with application configuration.
  This will _not_ override capabilities passed in directly to `Wallaby.start_session/1`.

  ```
  config :wallaby,
    chromedriver: [
      binary: "path/to/chrome"
    ]
  ```

  ## Default Capabilities

  By default, Chromdriver will use the following capabilities

  You can read more about capabilities in the [JSON Wire Protocol](https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#capabilities-json-object) documentation and the [Chromedriver](https://sites.google.com/a/chromium.org/chromedriver/capabilities) documentation.

  ```elixir
    %{
      javascriptEnabled: false,
      loadImages: false,
      version: "",
      rotatable: false,
      takesScreenshot: true,
      cssSelectorsEnabled: true,
      nativeEvents: false,
      platform: "ANY",
      unhandledPromptBehavior: "accept",
      loggingPrefs: %{
        browser: "DEBUG"
      },
      chromeOptions: %{
        args: [
          "--no-sandbox",
          "window-size=1280,800",
          "--disable-gpu",
          "--headless",
          "--fullscreen",
          "--user-agent=Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
        ]
      }
    }
  ```

  ## Notes

  This driver requires [Chromedriver](https://sites.google.com/a/chromium.org/chromedriver/) to be installed in your path.
  """
  use Supervisor

  @behaviour Wallaby.Driver

  @chromedriver_version_regex ~r/^ChromeDriver (\d+)\.(\d+)/

  alias Wallaby.{DependencyError, Metadata}
  alias Wallaby.Experimental.Chrome.{Chromedriver}
  alias Wallaby.Experimental.Selenium.WebdriverClient
  import Wallaby.Driver.LogChecker

  @typedoc """
  Options to pass to Wallaby.start_session/1

  ```elixir
  Wallaby.start_session(
    capabilities: %{chromeOptions: %{args: ["--headless"]}},
    create_session_fn: fn url, capabilities ->
      WebdriverClient.create_session(url, capabilities)
    end
  )
  ```
  """
  @type start_session_opts ::
          {:capabilities, map}
          | {:create_session_fn, (String.t(), map -> {:ok, %{}})}

  @doc false
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc false
  def init(:ok) do
    children = [
      worker(Wallaby.Experimental.Chrome.Chromedriver, []),
      worker(Wallaby.Driver.LogStore, [[]])
    ]

    supervise(children, strategy: :one_for_one)
  end

  @doc false
  def validate do
    with {:ok, executable} <- find_chromedriver_executable() do
      {version, 0} = System.cmd(executable, ["--version"])

      @chromedriver_version_regex
      |> Regex.run(version)
      |> Enum.drop(1)
      |> Enum.map(&String.to_integer/1)
      |> version_check()
    end
  end

  @doc false
  def find_chromedriver_executable do
    with {:error, :not_found} <-
           :wallaby
           |> Application.get_env(:chromedriver, [])
           |> Keyword.get(:path, "")
           |> Path.expand()
           |> do_find_chromedriver(),
         {:error, :not_found} <- do_find_chromedriver("chromedriver") do
      exception =
        DependencyError.exception("""
        Wallaby can't find chromedriver. Make sure you have chromedriver installed
        and included in your path.
        You can also provide a path using `config :wallaby, chromedriver: <path>`.
        """)

      {:error, exception}
    end
  end

  defp do_find_chromedriver(executable) do
    executable
    |> System.find_executable()
    |> case do
      path when not is_nil(path) -> {:ok, path}
      nil -> {:error, :not_found}
    end
  end

  defp version_check([major_version, _minor_version]) when major_version > 2 do
    :ok
  end

  defp version_check([major_version, minor_version])
       when major_version == 2 and minor_version >= 30 do
    :ok
  end

  defp version_check(_version) do
    exception =
      DependencyError.exception("""
      Looks like you're trying to run an older version of chromedriver. Wallaby needs at least
      chromedriver 2.30 to run correctly.
      """)

    {:error, exception}
  end

  @doc false
  @spec start_session([start_session_opts]) :: Wallaby.Driver.on_start_session() | no_return
  def start_session(opts \\ []) do
    {:ok, base_url} = Chromedriver.base_url()
    create_session_fn = Keyword.get(opts, :create_session_fn, &WebdriverClient.create_session/2)

    capabilities = Keyword.get(opts, :capabilities, capabilities_from_config(opts))

    with {:ok, response} <- create_session_fn.(base_url, capabilities) do
      id = response["sessionId"]

      if id == nil do
        raise inspect(response)
      end

      session = %Wallaby.Session{
        session_url: base_url <> "session/#{id}",
        url: base_url <> "session/#{id}",
        id: id,
        driver: __MODULE__,
        server: Chromedriver
      }

      if window_size = Keyword.get(opts, :window_size),
        do: {:ok, _} = set_window_size(session, window_size[:width], window_size[:height])

      {:ok, session}
    else
      error ->
        raise inspect(error)
    end
  end

  defp capabilities_from_config(opts) do
    :wallaby
    |> Application.get_env(:chromedriver, [])
    |> Keyword.get(:capabilities, default_capabilities(opts))
    |> put_headless_config()
    |> put_binary_config()
  end

  @doc false
  def end_session(%Wallaby.Session{} = session, opts \\ []) do
    end_session_fn = Keyword.get(opts, :end_session_fn, &WebdriverClient.delete_session/1)
    end_session_fn.(session)
    :ok
  end

  @doc false
  def blank_page?(session) do
    case current_url(session) do
      {:ok, url} ->
        url == "data:,"

      _ ->
        false
    end
  end

  defp delegate(fun, element_or_session, args \\ []) do
    check_logs!(element_or_session, fn ->
      apply(WebdriverClient, fun, [element_or_session | args])
    end)
  end

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
  defdelegate parse_log(log), to: Wallaby.Experimental.Chrome.Logger

  @doc false
  def window_handle(session), do: delegate(:window_handle, session)
  @doc false
  def window_handles(session), do: delegate(:window_handles, session)
  @doc false
  def focus_window(session, window_handle), do: delegate(:focus_window, session, [window_handle])
  @doc false
  def close_window(session), do: delegate(:close_window, session)
  @doc false
  def get_window_size(session), do: delegate(:get_window_size, session)
  @doc false
  def set_window_size(session, width, height),
    do: delegate(:set_window_size, session, [width, height])

  @doc false
  def get_window_position(session), do: delegate(:get_window_position, session)
  @doc false
  def set_window_position(session, x, y), do: delegate(:set_window_position, session, [x, y])
  @doc false
  def maximize_window(session), do: delegate(:maximize_window, session)
  @doc false
  def focus_frame(session, frame), do: delegate(:focus_frame, session, [frame])
  @doc false
  def focus_parent_frame(session), do: delegate(:focus_parent_frame, session)
  @doc false
  def cookies(session), do: delegate(:cookies, session)
  @doc false
  def current_path(session), do: delegate(:current_path, session)
  @doc false
  def current_url(session), do: delegate(:current_url, session)
  @doc false
  def page_title(session), do: delegate(:page_title, session)
  @doc false
  def page_source(session), do: delegate(:page_source, session)
  @doc false
  def set_cookie(session, key, value), do: delegate(:set_cookie, session, [key, value])
  @doc false
  def visit(session, url), do: delegate(:visit, session, [url])
  @doc false
  def attribute(element, name), do: delegate(:attribute, element, [name])
  @doc false
  def click(element), do: delegate(:click, element)
  @doc false
  def click(parent, button), do: delegate(:click, parent, [button])
  @doc false
  def double_click(parent), do: delegate(:double_click, parent)
  @doc false
  def button_down(parent, button), do: delegate(:button_down, parent, [button])
  @doc false
  def button_up(parent, button), do: delegate(:button_up, parent, [button])
  @doc false
  def hover(element), do: delegate(:move_mouse_to, element, [element])
  @doc false
  def move_mouse_by(parent, x_offset, y_offset),
    do: delegate(:move_mouse_to, parent, [nil, x_offset, y_offset])

  @doc false
  def clear(element), do: delegate(:clear, element)
  @doc false
  def displayed(element), do: delegate(:displayed, element)
  @doc false
  def selected(element), do: delegate(:selected, element)
  @doc false
  def set_value(element, value), do: delegate(:set_value, element, [value])
  @doc false
  def text(element), do: delegate(:text, element)

  @doc false
  def execute_script(session_or_element, script, args \\ [], opts \\ []) do
    check_logs = Keyword.get(opts, :check_logs, true)

    request_fn = fn ->
      WebdriverClient.execute_script(session_or_element, script, args)
    end

    if check_logs do
      check_logs!(session_or_element, request_fn)
    else
      request_fn.()
    end
  end

  @doc false
  def execute_script_async(session_or_element, script, args \\ [], opts \\ []) do
    check_logs = Keyword.get(opts, :check_logs, true)

    request_fn = fn ->
      WebdriverClient.execute_script_async(session_or_element, script, args)
    end

    if check_logs do
      check_logs!(session_or_element, request_fn)
    else
      request_fn.()
    end
  end

  @doc false
  def find_elements(session_or_element, compiled_query),
    do: delegate(:find_elements, session_or_element, [compiled_query])

  @doc false
  def send_keys(session_or_element, keys), do: delegate(:send_keys, session_or_element, [keys])
  @doc false
  def take_screenshot(session_or_element), do: delegate(:take_screenshot, session_or_element)
  @doc false
  defdelegate log(session_or_element), to: WebdriverClient

  defp default_capabilities(opts) do
    user_agent =
      Metadata.append(
        "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36",
        opts[:metadata]
      )

    %{
      javascriptEnabled: false,
      loadImages: false,
      version: "",
      rotatable: false,
      takesScreenshot: true,
      cssSelectorsEnabled: true,
      nativeEvents: false,
      platform: "ANY",
      unhandledPromptBehavior: "accept",
      loggingPrefs: %{
        browser: "DEBUG"
      },
      chromeOptions: %{
        args: [
          "--no-sandbox",
          "window-size=1280,800",
          "--disable-gpu",
          "--headless",
          "--fullscreen",
          "--user-agent=#{user_agent}"
        ]
      }
    }
  end

  defp put_headless_config(capabilities) do
    headless? = Application.get_env(:wallaby, :chromedriver, []) |> Keyword.get(:headless)

    capabilities
    |> update_unless_nil(:args, headless?, fn args ->
      if headless? do
        (args ++ ["--headless"])
        |> Enum.uniq()
      else
        args -- ["--headless"]
      end
    end)
  end

  defp put_binary_config(capabilities) do
    binary_path = Application.get_env(:wallaby, :chromedriver, []) |> Keyword.get(:binary)

    capabilities
    |> update_unless_nil(:binary, binary_path, fn _ ->
      binary_path
    end)
  end

  defp update_unless_nil(capabilities, _key, nil, _updater), do: capabilities

  defp update_unless_nil(capabilities, key, _, updater) do
    capabilities
    |> update_in([:chromeOptions, key], updater)
  end
end
