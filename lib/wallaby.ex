defmodule Wallaby do
  use Application

  def start(_type, _args) do
    pool_opts =
      [name: {:local, Wallaby.ServerPool},
       worker_module: Wallaby.Servers.PhantomJS,
       size: :erlang.system_info(:schedulers_online),
       max_overflow: 0]

    :poolboy.start_link(pool_opts, [])
  end


  def start_session do
    server = :poolboy.checkout(Wallaby.ServerPool)
    Wallaby.Sessions.PhantomJS.create(server)
  end

  def end_session(_session) do

  end
end
