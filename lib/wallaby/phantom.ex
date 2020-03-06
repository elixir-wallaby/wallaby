defmodule Wallaby.Phantom do
  @moduledoc """
  Wallaby driver for PhantomJS.

  ## Usage

  Start a Wallaby Session using this driver with the following command:

  ```
  {:ok, session} = Wallaby.start_session()
  ```

  ## Notes

  This driver requires PhantomJS be installed in your path. You can install PhantomJS through NPM or your package manager of choice:

  ```
  $ npm install -g phantomjs-prebuilt
  ```

  If you need to specify a specific PhantomJS you can pass the path in the configuration:

  ```
  config :wallaby, phantomjs: "node_modules/.bin/phantomjs"
  ```

  You can also pass arguments to PhantomJS through the `phantomjs_args` config setting, e.g.:

  ```
  config :wallaby, phantomjs_args: "--webdriver-logfile=phantomjs.log"
  ```
  """

  use Supervisor

  alias Wallaby.Phantom.Driver
  alias Wallaby.Phantom.ServerPool
  alias Wallaby.DependencyError

  @behaviour Wallaby.Driver

  @doc false
  def start_link(opts \\ []) do
    {:ok, phantomjs_path} = find_phantomjs_executable()

    Supervisor.start_link(__MODULE__, %{phantomjs_path: phantomjs_path}, opts)
  end

  def validate do
    case find_phantomjs_executable() do
      {:ok, _path} ->
        :ok

      {:error, :not_found} ->
        exception =
          DependencyError.exception("""
          Wallaby can't find phantomjs. Make sure you have phantomjs installed
          and included in your path, or that your `config :wallaby, :phantomjs`
          setting points to a valid phantomjs executable.
          """)

        {:error, exception}
    end
  end

  def init(%{phantomjs_path: phantomjs_path}) do
    children = [
      {ServerPool, [phantomjs_path]},
      Wallaby.Driver.LogStore
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc false
  @spec find_phantomjs_executable :: {:ok, String.t()} | {:error, :not_found}
  def find_phantomjs_executable do
    phantom_path = Application.get_env(:wallaby, :phantomjs, "phantomjs")

    [Path.expand(phantom_path), phantom_path]
    |> Enum.find(&System.find_executable/1)
    |> case do
      path when is_binary(path) ->
        {:ok, path}

      nil ->
        {:error, :not_found}
    end
  end

  @doc false
  def capabilities(opts) do
    default_capabilities()
    |> Map.merge(user_agent_capability(opts[:user_agent]))
    |> Map.merge(custom_headers_capability(opts[:custom_headers]))
  end

  @doc false
  def default_capabilities do
    %{
      javascriptEnabled: true,
      loadImages: false,
      version: "",
      rotatable: false,
      takesScreenshot: true,
      cssSelectorsEnabled: true,
      browserName: "phantomjs",
      nativeEvents: false,
      platform: "ANY"
    }
  end

  @doc false
  def start_session(opts) do
    {:ok, server} = ServerPool.checkout()
    Wallaby.Phantom.Driver.create(server, opts)
  end

  @doc false
  def end_session(%Wallaby.Session{server: server} = session) do
    Driver.execute_script(session, "localStorage.clear()", [], check_logs: false)
    Driver.delete(session)
    ServerPool.check_in(server)
  end

  def blank_page?(session) do
    case current_url(session) do
      {:ok, url} -> url == "about:blank"
      _ -> false
    end
  end

  @doc false
  defdelegate accept_alert(session, open_dialog_fn), to: Driver
  @doc false
  defdelegate accept_confirm(session, open_dialog_fn), to: Driver
  @doc false
  defdelegate accept_prompt(session, input_va, open_dialog_fn), to: Driver
  @doc false
  defdelegate cookies(session), to: Driver
  @doc false
  defdelegate current_path(session), to: Driver
  @doc false
  defdelegate current_url(session), to: Driver
  @doc false
  defdelegate dismiss_confirm(session, open_dialog_fn), to: Driver
  @doc false
  defdelegate dismiss_prompt(session, open_dialog_fn), to: Driver
  @doc false
  defdelegate get_window_size(session), to: Driver
  @doc false
  defdelegate page_title(session), to: Driver
  @doc false
  defdelegate page_source(session), to: Driver
  @doc false
  defdelegate set_cookie(session, key, value), to: Driver
  @doc false
  defdelegate set_window_size(session, width, height), to: Driver
  @doc false
  defdelegate visit(session, url), to: Driver

  @doc false
  defdelegate attribute(element, name), to: Driver
  @doc false
  defdelegate click(element), to: Driver
  @doc false
  defdelegate clear(element), to: Driver
  @doc false
  defdelegate displayed(element), to: Driver
  @doc false
  defdelegate selected(element), to: Driver
  @doc false
  defdelegate set_value(element, value), to: Driver
  @doc false
  defdelegate text(element), to: Driver

  @doc false
  defdelegate execute_script(session_or_element, script, args), to: Driver
  @doc false
  defdelegate execute_script_async(session_or_element, script, args), to: Driver
  @doc false
  defdelegate find_elements(session_or_element, compiled_query), to: Driver
  @doc false
  defdelegate send_keys(session_or_element, keys), to: Driver
  @doc false
  defdelegate take_screenshot(session_or_element), to: Driver
  defdelegate log(session_or_element), to: Driver
  defdelegate parse_log(log), to: Wallaby.Phantom.Logger

  @doc false
  def user_agent do
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/538.1 (KHTML, like Gecko) PhantomJS/2.1.1 Safari/538.1"
  end

  @doc false
  def user_agent_capability(nil), do: %{}

  def user_agent_capability(ua) do
    %{"phantomjs.page.settings.userAgent" => ua}
  end

  @doc false
  def custom_headers_capability(nil), do: %{}

  def custom_headers_capability(ch) do
    Enum.reduce(ch, %{}, fn {k, v}, acc ->
      Map.merge(acc, %{"phantomjs.page.customHeaders.#{k}" => v})
    end)
  end

  def window_handle(_session), do: {:error, :not_supported}
  def window_handles(_session), do: {:error, :not_supported}
  def focus_window(_session, _window_handle), do: {:error, :not_supported}
  def close_window(_session), do: {:error, :not_supported}
  def get_window_position(_session), do: {:error, :not_supported}
  def set_window_position(_session, _x, _y), do: {:error, :not_supported}
  def maximize_window(_session), do: {:error, :not_supported}
  def focus_frame(_session, _frame), do: {:error, :not_supported}
  def focus_parent_frame(_session), do: {:error, :not_supported}
end
