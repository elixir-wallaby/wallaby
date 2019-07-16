defmodule Wallaby.Experimental.Chrome do
  @moduledoc false
  use Supervisor

  @behaviour Wallaby.Driver

  @chromedriver_version_regex ~r/^ChromeDriver (\d+)\.(\d+)/

  alias Wallaby.{Session, DependencyError, Metadata}
  alias Wallaby.Experimental.Chrome.{Chromedriver}
  alias Wallaby.Experimental.Selenium.WebdriverClient
  import Wallaby.Driver.LogChecker

  @doc false
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      worker(Wallaby.Experimental.Chrome.Chromedriver, []),
      worker(Wallaby.Driver.LogStore, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

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

  def find_chromedriver_executable do
    with {:error, :not_found} <-
            :wallaby
            |> Application.get_env(:chromedriver, "")
            |>  Path.expand()
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

  def start_session(opts) do
    {:ok, base_url} = Chromedriver.base_url()
    create_session_fn = Keyword.get(opts, :create_session_fn, &WebdriverClient.create_session/2)

    user_agent =
      user_agent()
      |> Metadata.append(opts[:metadata])

    capabilities = capabilities(user_agent: user_agent)

    with {:ok, response} <- create_session_fn.(base_url, capabilities) do
      id = response["sessionId"]

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
    end
  end

  def end_session(%Wallaby.Session{} = session, opts \\ []) do
    end_session_fn = Keyword.get(opts, :end_session_fn, &WebdriverClient.delete_session/1)
    end_session_fn.(session)
    :ok
  end

  def blank_page?(session) do
    case current_url(session) do
      {:ok, url} ->
        url == "data:,"

      _ ->
        false
    end
  end

  def get_window_size(%Session{} = session) do
    handle = delegate(:window_handle, session)
    delegate(:get_window_size, session, [handle])
  end

  def set_window_size(session, width, height) do
    handle = delegate(:window_handle, session)
    delegate(:set_window_size, session, [handle, width, height])
  end

  defp delegate(fun, element_or_session, args \\ []) do
    check_logs!(element_or_session, fn ->
      apply(WebdriverClient, fun, [element_or_session | args])
    end)
  end

  defdelegate accept_alert(session, fun), to: WebdriverClient
  defdelegate dismiss_alert(session, fun), to: WebdriverClient
  defdelegate accept_confirm(session, fun), to: WebdriverClient
  defdelegate dismiss_confirm(session, fun), to: WebdriverClient
  defdelegate accept_prompt(session, input, fun), to: WebdriverClient
  defdelegate dismiss_prompt(session, fun), to: WebdriverClient
  defdelegate parse_log(log), to: Wallaby.Experimental.Chrome.Logger

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
  def find_elements(session_or_element, compiled_query),
    do: delegate(:find_elements, session_or_element, [compiled_query])

  @doc false
  def send_keys(session_or_element, keys), do: delegate(:send_keys, session_or_element, [keys])
  @doc false
  def take_screenshot(session_or_element), do: delegate(:take_screenshot, session_or_element)
  @doc false
  defdelegate log(session_or_element), to: WebdriverClient

  @doc false
  def user_agent do
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
  end

  defp capabilities(opts) do
    default_capabilities()
    |> Map.put(:chromeOptions, chrome_options(opts))
  end

  defp default_capabilities do
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
      }
    }
  end

  defp chrome_options(opts) do
    %{args: chrome_args(opts)}
    |> put_unless_nil(:binary, chrome_binary_option())
  end

  defp chrome_args(opts) do
    default_chrome_args()
    |> Enum.concat(headless_args())
    |> Enum.concat(user_agent_arg(opts[:user_agent]))
  end

  defp user_agent_arg(nil), do: []
  defp user_agent_arg(ua), do: ["--user-agent=#{ua}"]

  defp headless? do
    :wallaby
    |> Application.get_env(:chrome, [])
    |> Keyword.get(:headless, true)
  end

  defp chrome_binary_option do
    :wallaby
    |> Application.get_env(:chrome, [])
    |> Keyword.get(:binary)
  end

  def default_chrome_args do
    [
      "--no-sandbox",
      "window-size=1280,800",
      "--disable-gpu"
    ]
  end

  defp headless_args do
    if headless?() do
      ["--fullscreen", "--headless"]
    else
      []
    end
  end

  defp put_unless_nil(map, _key, nil), do: map
  defp put_unless_nil(map, key, value), do: Map.put(map, key, value)
end
