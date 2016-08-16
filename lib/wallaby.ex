defmodule Wallaby do
  @moduledoc """
  A concurrent feature testing library.

  ## Configuration

  Wallaby supports the following options:

  * `:pool_size` - Maximum amount of phantoms to run. The default is `:erlang.system_info(:schedulers_online) * 2`.
  * `:screenshot_dir` - The directory to store screenshots.
  * `:screenshot_on_failure` - if Wallaby should take screenshots on test failures (defaults to `false`).
  * `:max_wait_time` - The amount of time that Wallaby should wait to find an element on the page. (defaults to `3_000`)
  * `:js_errors` - if Wallaby should re-throw javascript errors in elixir (defaults to true).
  """
  use Application

  @pool_name Wallaby.ServerPool

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(@pool_name, poolboy_config, []),
      worker(Wallaby.LogStore, []),
    ]

    opts = [strategy: :one_for_one, name: Wallaby.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_session(opts \\ []) do
    server = :poolboy.checkout(@pool_name)
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

  def js_errors? do
    Application.get_env(:wallaby, :js_errors)
    |> explicitly_set()
  end

  defp explicitly_set(:false), do: false
  defp explicitly_set(_), do: true

  defp poolboy_config do
    [name: {:local, @pool_name},
     worker_module: Wallaby.Server,
     size: pool_size,
     max_overflow: 0]
  end

  defp default_pool_size do
    :erlang.system_info(:schedulers_online)
  end
end
