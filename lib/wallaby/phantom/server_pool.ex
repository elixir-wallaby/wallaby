defmodule Wallaby.Phantom.ServerPool do
  @moduledoc false

  alias Wallaby.Utils.ResourcePool

  @instance __MODULE__

  def child_spec([phantomjs_path]) when is_binary(phantomjs_path) do
    ResourcePool.child_spec(
      name: @instance,
      worker: {Wallaby.Phantom.Server, phantomjs_path: phantomjs_path},
      size: pool_size(),
      max_overflow: 0
    )
  end

  @spec checkout() :: {:ok, pid} | {:error, :full}
  def checkout do
    ResourcePool.checkout(@instance, block?: true, timeout: :infinity)
  end

  @spec check_in(pid) :: :ok
  def check_in(server) do
    ResourcePool.checkin(@instance, server)
  end

  defp pool_size do
    Application.get_env(:wallaby, :pool_size) || default_pool_size()
  end

  defp default_pool_size do
    :erlang.system_info(:schedulers_online)
  end
end
