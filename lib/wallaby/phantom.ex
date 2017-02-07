defmodule Wallaby.Phantom do
  use Supervisor

  alias Wallaby.Phantom.Driver

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

  def user_agent do
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/538.1 (KHTML, like Gecko) PhantomJS/2.1.1 Safari/538.1"
  end

  def user_agent_capability(nil), do: %{}
  def user_agent_capability(ua) do
    %{"phantomjs.page.settings.userAgent" => ua}
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
