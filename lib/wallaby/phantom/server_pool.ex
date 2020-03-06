defmodule Wallaby.Phantom.ServerPool do
  @moduledoc false

  @instance __MODULE__

  def child_spec([phantomjs_path]) when is_binary(phantomjs_path) do
    @instance
    |> :poolboy.child_spec(poolboy_config(), phantom_path: phantomjs_path)
    |> from_deprecated_child_spec()
  end

  @spec checkout() :: {:ok, pid} | {:error, :full}
  def checkout do
    case :poolboy.checkout(@instance, true, :infinity) do
      pid when is_pid(pid) -> {:ok, pid}
      :full -> {:error, :full}
    end
  end

  @spec check_in(pid) :: :ok
  def check_in(server) do
    :poolboy.checkin(@instance, server)
  end

  defp poolboy_config do
    [
      name: {:local, @instance},
      worker_module: Wallaby.Phantom.Server,
      size: pool_size(),
      max_overflow: 0
    ]
  end

  defp pool_size do
    Application.get_env(:wallaby, :pool_size) || default_pool_size()
  end

  defp default_pool_size do
    :erlang.system_info(:schedulers_online)
  end

  defp from_deprecated_child_spec({child_id, start_mfa, restart, shutdown, worker, modules}) do
    %{
      id: child_id,
      start: start_mfa,
      restart: restart,
      shutdown: shutdown,
      worker: worker,
      modules: modules
    }
  end
end
