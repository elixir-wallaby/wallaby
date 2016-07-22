defmodule Wallaby do
  @moduledoc """
  A concurrent feature testing library.

  ## Configuration

  Wallaby supports the following options:

  * `:pool_size` - Maximum amount of phantoms to run. The default is `:erlang.system_info(:schedulers_online) * 2`.
  * `:screenshot_dir` - The directory to store screenshots.
  * `:screenshot_on_failure` - if Wallaby should take screenshots on test failures (defaults to `false`).
  * `:max_wait_time` - The amount of time that Wallaby should wait to find an element on the page. (defaults to `3_000`)
  """
  use Application

  def start(_type, _args) do
    pool_opts =
      [name: {:local, Wallaby.ServerPool},
       worker_module: Wallaby.Server,
       size: pool_size,
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

  def pool_size do
    Application.get_env(:wallaby, :pool_size) || default_pool_size
  end

  defp default_pool_size do
    :erlang.system_info(:schedulers_online)
  end
end
