defmodule Wallaby do
  use Application

  def start(_type, _args) do
    pool_opts =
      [name: {:local, Wallaby.ServerPool},
       worker_module: Wallaby.Server,
       size: :erlang.system_info(:schedulers_online) * 2,
       max_overflow: 0]

    :poolboy.start_link(pool_opts, [])
  end

  def start_session(opts \\ []) do
    server = :poolboy.checkout(Wallaby.ServerPool)
    Wallaby.Driver.create(server, opts)
  end

  def end_session(%Wallaby.Session{server: server}) do
    :poolboy.checkin(Wallaby.ServerPool, server)
  end

  def screenshot_on_failure? do
    Application.get_env(:wallaby, :screenshot_on_failure)
  end
end
