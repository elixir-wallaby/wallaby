defmodule Wallaby.Utils.ResourcePool do
  @moduledoc false

  # This is a wrapper around poolboy that makes it play nicer
  # with Elixir's child_spec

  @type pool :: GenServer.server()

  def child_spec(opts) do
    name = Keyword.fetch!(opts, :name)
    additional_opts = Keyword.take(opts, [:size, :max_overflow, :strategy])

    {worker_module, worker_opts} =
      opts
      |> Keyword.fetch!(:worker)
      |> extract_worker_info()

    name
    |> :poolboy.child_spec(
      [name: {:local, name}, worker_module: worker_module] ++ additional_opts,
      worker_opts
    )
    |> from_deprecated_child_spec()
  end

  @type checkout_opt :: {:block?, boolean} | {:timeout, timeout}

  @spec checkout(pool, [checkout_opt]) :: {:ok, pid} | {:error, :full}
  def checkout(pool, opts \\ []) when is_list(opts) do
    block? = Keyword.get(opts, :block?, true)
    timeout = Keyword.get(opts, :timeout, 5_000)

    case :poolboy.checkout(pool, block?, timeout) do
      pid when is_pid(pid) -> {:ok, pid}
      :full -> {:error, :full}
    end
  end

  @spec checkin(pool, pid) :: :ok
  def checkin(pool, pid) do
    :poolboy.checkin(pool, pid)
  end

  defp extract_worker_info(worker_def)
  defp extract_worker_info(worker_module) when is_atom(worker_module), do: {worker_module, []}

  defp extract_worker_info({worker_module, worker_opts}) when is_atom(worker_module),
    do: {worker_module, worker_opts}

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
