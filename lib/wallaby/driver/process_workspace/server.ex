defmodule Wallaby.Driver.ProcessWorkspace.Server do
  @moduledoc false

  use GenServer

  @spec start_link(pid, String.t) :: GenServer.on_start
  def start_link(process_pid, workspace_path) do
    GenServer.start_link(__MODULE__, [process_pid, workspace_path])
  end

  @impl GenServer
  def init([process_pid, workspace_path]) do
    Process.flag(:trap_exit, true)
    ref = Process.monitor(process_pid)
    File.mkdir(workspace_path)

    {:ok, %{ref: ref, workspace_path: workspace_path}}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _, _}, %{ref: ref, workspace_path: workspace_path} = state) do
    File.rm_rf(workspace_path)
    {:stop, :normal, state}
  end
  def handle_info(_, state), do: {:noreply, state}

  @impl GenServer
  def terminate(:shutdown, %{workspace_path: workspace_path}) do
    File.rm_rf(workspace_path)
  end
  def terminate(_, _), do: :ok
end
