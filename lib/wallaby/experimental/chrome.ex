defmodule Wallaby.Experimental.Chrome do
  use Supervisor
  @behaviour Wallaby.Driver

  @pool_name Wallaby.ChromedriverPool
  @chromedriver_version_regex ~r/^ChromeDriver 2\.(\d+).(\d+) \(.*\)/

  alias Wallaby.Session
  alias Wallaby.Experimental.Chrome.{Webdriver, Chromedriver, Sessions}
  alias Wallaby.Experimental.Selenium.WebdriverClient

  @doc false
  def start_link(opts\\[]) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      :poolboy.child_spec(@pool_name, poolboy_config(), []),
      worker(Wallaby.Experimental.Chrome.Sessions, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def validate() do
    case System.find_executable("chromedriver") do
      chromedriver when not is_nil(chromedriver) ->
        {version, 0} = System.cmd("chromedriver", ["--version"])
        version =
          Regex.run(@chromedriver_version_regex, version)
          |> Enum.at(1)
          |> String.to_integer

        if version >= 30 do
          :ok
        else
          exception = Wallaby.DependencyException.exception """
          Looks like you're trying to run an older version of chromedriver. Wallaby needs at least
          chromedriver 2.30 to run correctly.
          """
          {:error, exception}
        end
      _ ->
        exception = Wallaby.DependencyException.exception """
        Wallaby can't find chromedriver. Make sure you have chromedriver installed
        and included in your path.
        """
        {:error, exception}
    end
  end

  def start_session(opts \\ []) do
    chromedriver = :poolboy.checkout(@pool_name, true, :infinity)
    start_session(chromedriver, opts)
  end

  def start_session(chromedriver, opts) do
    {:ok, base_url} = Chromedriver.base_url(chromedriver)
    capabilities = Keyword.get(opts, :capabilities, %{})
    create_session_fn = Keyword.get(opts, :create_session_fn,
                                    &Webdriver.create_session/2)

    capabilities = Map.merge(default_capabilities(), capabilities)

    with {:ok, response} <- create_session_fn.(base_url, capabilities) do
      id = response["sessionId"]

      session = %Wallaby.Session{
        session_url: base_url <> "session/#{id}",
        url: base_url <> "session/#{id}",
        id: id,
        driver: __MODULE__,
        server: chromedriver,
      }
      :ok = Sessions.monitor(session)

      {:ok, session}
    end
  end

  def end_session(%Wallaby.Session{server: server}=session, opts \\ []) do
    end_session_fn = Keyword.get(opts, :end_session_fn, &WebdriverClient.delete_session/1)
    end_session_fn.(session)
    :poolboy.checkin(@pool_name, server)
    :ok
  end

  def blank_page?(session) do
    with {:ok, url} <- current_url(session) do
      url == "data:,"
    end
  end

  def get_window_size(%Session{} = session) do
    handle = WebdriverClient.window_handle(session)
    WebdriverClient.get_window_size(session, handle)
  end

  def set_window_size(session, width, height) do
    handle = WebdriverClient.window_handle(session)
    WebdriverClient.set_window_size(session, handle, width, height)
  end

  def accept_dialogs(_session), do: {:error, :not_implemented}
  def dismiss_dialogs(_session), do: {:error, :not_implemented}
  def accept_alert(_session, _fun), do: {:error, :not_implemented}
  def dismiss_alert(_session, _fun), do: {:error, :not_implemented}
  def accept_confirm(_session, _fun), do: {:error, :not_implemented}
  def dismiss_confirm(_session, _fun), do: {:error, :not_implemented}
  def accept_prompt(_session, _input, _fun), do: {:error, :not_implemented}
  def dismiss_prompt(_session, _fun), do: {:error, :not_implemented}
  @doc false
  defdelegate cookies(session),                                   to: WebdriverClient
  @doc false
  defdelegate current_path(session),                              to: WebdriverClient
  @doc false
  defdelegate current_url(session),                               to: WebdriverClient
  @doc false
  defdelegate page_title(session),                                to: WebdriverClient
  @doc false
  defdelegate page_source(session),                               to: WebdriverClient
  @doc false
  defdelegate set_cookie(session, key, value),                    to: WebdriverClient
  @doc false
  defdelegate visit(session, url),                                to: WebdriverClient

  @doc false
  defdelegate attribute(element, name),                           to: WebdriverClient
  @doc false
  defdelegate click(element),                                     to: WebdriverClient
  @doc false
  defdelegate clear(element),                                     to: WebdriverClient
  @doc false
  defdelegate displayed(element),                                 to: WebdriverClient
  @doc false
  defdelegate selected(element),                                  to: WebdriverClient
  @doc false
  defdelegate set_value(element, value),                          to: WebdriverClient
  @doc false
  defdelegate text(element),                                      to: WebdriverClient

  @doc false
  defdelegate execute_script(session_or_element, script, args),   to: WebdriverClient
  @doc false
  defdelegate find_elements(session_or_element, compiled_query),  to: WebdriverClient
  @doc false
  defdelegate send_keys(session_or_element, keys),                to: WebdriverClient
  @doc false
  defdelegate take_screenshot(session_or_element),                to: WebdriverClient

  @doc false
  def user_agent do
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
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
      chromeOptions: %{
        args: [
          "--no-sandbox",
          "window-size=1280,800",
          "--headless",
          "--disable-gpu"
        ]
      }
    }
  end

  defp poolboy_config(), do: [
    name: {:local, @pool_name},
    worker_module: Wallaby.Experimental.Chrome.Chromedriver,
    size: pool_size(),
    max_overflow: 0,
  ]

  defp pool_size, do: Application.get_env(:wallaby, :pool_size) || default_pool_size()

  defp default_pool_size, do: :erlang.system_info(:schedulers_online)/2
end
