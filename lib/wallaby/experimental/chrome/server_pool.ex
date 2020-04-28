defmodule Wallaby.Experimental.Chrome.ServerPool do
  @moduledoc false

  alias Wallaby.Experimental.Chrome

  def child_spec(_arg) do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    __MODULE__
    |> :poolboy.child_spec(poolboy_config(), chromedriver_path)
    |> from_deprecated_child_spec()
  end

  @spec checkout() :: {:ok, pid} | {:error, :full}
  def checkout do
    case :poolboy.checkout(:chrome_instances, true, :infinity) do
      pid when is_pid(pid) ->
        {:ok, pid}

      :full ->
        {:error, :full}
    end
  end

  @spec check_in(pid) :: :ok
  def check_in(server) do
    :poolboy.checkin(__MODULE__, server)
  end

  defp poolboy_config do
    [
      name: {:local, :chrome_instances},
      worker_module: Wallaby.Experimental.Chrome.Chromedriver.Server,
      size: pool_size(),
      max_overflow: 0
    ]
  end

  defp pool_size do
    Application.get_env(:wallaby, :pool_size) || default_pool_size()
  end

  defp default_pool_size do
    # ExUnit's default for max_cases is schedulers online times 2
    # The pool size should be greater than or equal to this to prevent
    # tests from queuing for workers
    :erlang.system_info(:schedulers_online) * 2
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
