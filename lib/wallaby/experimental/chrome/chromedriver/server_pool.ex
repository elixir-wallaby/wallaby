defmodule Wallaby.Experimental.Chrome.Chromedriver.ServerPool do
  @moduledoc false
  @instance __MODULE__

  alias Wallaby.Experimental.Chrome
  alias Wallaby.Utils.ResourcePool

  def child_spec(_) do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    ResourcePool.child_spec(
      name: @instance,
      worker: {Wallaby.Experimental.Chrome.Chromedriver.Server, chromedriver_path},
      size: pool_size(),
      max_overflow: pool_size()
    )
  end

  @spec checkout!() :: pid | no_return()
  def checkout! do
    {:ok, pid} = ResourcePool.checkout(@instance, block?: true, timeout: :infinity)
    pid
  end

  @spec check_in(pid) :: :ok
  def check_in(server) do
    ResourcePool.checkin(@instance, server)
  end

  defp pool_size do
    Application.get_env(:wallaby, :pool_size) || System.schedulers_online()
  end
end
