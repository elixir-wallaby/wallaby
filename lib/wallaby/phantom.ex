defmodule Wallaby.Phantom do
  use Supervisor

  alias Wallaby.Phantom.Driver

  @behaviour Wallaby.Driver

  @moduledoc false
  @pool_name Wallaby.ServerPool

  def start_link(opts\\[]) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      :poolboy.child_spec(@pool_name, poolboy_config(), []),
      worker(Wallaby.Phantom.LogStore, []),
    ]

    supervise(children, strategy: :one_for_one)
  end

  def capabilities(opts) do
    default_capabilities()
    |> Map.merge(user_agent_capability(opts[:user_agent]))
    |> Map.merge(custom_headers_capability(opts[:custom_headers]))
  end

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
      platform: "ANY",
    }
  end

  def start_session(opts) do
    server = :poolboy.checkout(@pool_name, true, :infinity)
    Wallaby.Phantom.Driver.create(server, opts)
  end

  def end_session(%Wallaby.Session{server: server}=session) do
    Driver.execute_script(session, "localStorage.clear()")
    Driver.delete(session)
    :poolboy.checkin(Wallaby.ServerPool, server)
  end

  defdelegate accept_dialogs(session),                            to: Driver
  defdelegate accept_alert(session, open_dialog_fn),              to: Driver
  defdelegate accept_confirm(session, open_dialog_fn),            to: Driver
  defdelegate accept_prompt(session, input_va, open_dialog_fn),   to: Driver
  defdelegate cookies(session),                                   to: Driver
  defdelegate current_path!(session),                             to: Driver
  defdelegate current_url!(session),                              to: Driver
  defdelegate dismiss_dialogs(session),                           to: Driver
  defdelegate dismiss_confirm(session, open_dialog_fn),           to: Driver
  defdelegate dismiss_prompt(session, open_dialog_fn),            to: Driver
  defdelegate get_window_size(session),                           to: Driver
  defdelegate page_title(session),                                to: Driver
  defdelegate page_source(session),                               to: Driver
  defdelegate set_cookies(session, key, value),                   to: Driver
  defdelegate set_window_size(session, width, height),            to: Driver
  defdelegate visit(session, url),                                to: Driver

  defdelegate attribute(element, name),                           to: Driver
  defdelegate click(element),                                     to: Driver
  defdelegate clear(element),                                     to: Driver
  defdelegate displayed(element),                                 to: Driver
  defdelegate selected(element),                                  to: Driver
  defdelegate set_value(element, value),                          to: Driver
  defdelegate text(element),                                      to: Driver

  defdelegate execute_script(session_or_element, script, args),   to: Driver
  defdelegate find_elements(session_or_element, compiled_query),  to: Driver
  defdelegate send_keys(session_or_element, keys),                to: Driver
  defdelegate take_screenshot(session_or_element),                to: Driver

  def user_agent do
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/538.1 (KHTML, like Gecko) PhantomJS/2.1.1 Safari/538.1"
  end

  def user_agent_capability(nil), do: %{}
  def user_agent_capability(ua) do
    %{"phantomjs.page.settings.userAgent" => ua}
  end

  def custom_headers_capability(nil), do: %{}
  def custom_headers_capability(ch) do
    Enum.reduce(ch, %{}, fn ({k, v}, acc) ->
      Map.merge(acc, %{ "phantomjs.page.customHeaders.#{k}" => v })
    end)
  end

  def pool_size do
    Application.get_env(:wallaby, :pool_size) || default_pool_size()
  end

  defp poolboy_config do
    [name: {:local, @pool_name},
     worker_module: Wallaby.Phantom.Server,
     size: pool_size(),
     max_overflow: 0]
  end

  defp default_pool_size do
    :erlang.system_info(:schedulers_online)
  end
end
