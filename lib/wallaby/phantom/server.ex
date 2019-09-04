defmodule Wallaby.Phantom.Server do
  @moduledoc false
  use GenServer

  alias Wallaby.Driver.ProcessWorkspace
  alias Wallaby.Phantom.Server.ServerState
  alias Wallaby.Phantom.Server.StartTask

  @type os_pid :: non_neg_integer

  @type start_link_opt ::
    {:phantom_path, String.t}

  @spec start_link([start_link_opt]) :: GenServer.on_start
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args)
  end

  def stop(server) do
    GenServer.stop(server)
  end

  def get_base_url(server) do
    GenServer.call(server, :get_base_url)
  end

  @spec get_wrapper_os_pid(pid) :: os_pid
  def get_wrapper_os_pid(server) do
    GenServer.call(server, :get_wrapper_os_pid)
  end

  @spec get_os_pid(pid) :: os_pid
  def get_os_pid(server) do
    GenServer.call(server, :get_os_pid)
  end

  def get_local_storage_dir(server) do
    GenServer.call(server, :get_local_storage_dir)
  end

  def clear_local_storage(server) do
    GenServer.call(server, :clear_local_storage)
  end

  @impl GenServer
  def init(args) do
    {:ok, workspace_path} = ProcessWorkspace.create(self())

    case workspace_path |> ServerState.new(args) |> start_phantom() do
      {:ok, server_state} ->
        {:ok, server_state}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call(:get_base_url, _, state) do
    {:reply, ServerState.base_url(state), state}
  end

  def handle_call(:get_wrapper_os_pid, _, %ServerState{wrapper_script_os_pid: wrapper_script_os_pid} = state) do
    {:reply, wrapper_script_os_pid, state}
  end

  def handle_call(:get_os_pid, _, %ServerState{phantom_os_pid: phantom_os_pid} = state) do
    {:reply, phantom_os_pid, state}
  end

  def handle_call(:get_local_storage_dir, _from, state) do
    {:reply, ServerState.local_storage_path(state), state}
  end

  def handle_call(:clear_local_storage, _from, state) do
    result =
      state |> ServerState.local_storage_path |> File.rm_rf

    {:reply, result, state}
  end

  @impl GenServer
  def handle_info({port, {:data, _output}}, %ServerState{wrapper_script_port: port} = state) do
    {:noreply, state}
  end
  def handle_info({port, {:exit_status, status}}, %ServerState{wrapper_script_port: port} = state) do
    {:stop, {:exit_status, status}, state}
  end
  def handle_info(_, state), do: {:noreply, state}

  @impl GenServer
  def terminate(_reason, %ServerState{wrapper_script_port: wrapper_script_port, wrapper_script_os_pid: wrapper_script_os_pid}) do
    Port.close(wrapper_script_port)
    wait_for_stop(wrapper_script_os_pid)
  end

  @spec start_phantom(ServerState.t) ::
    {:ok, ServerState.t} | {:error, StartTask.error_reason}
  defp start_phantom(%ServerState{} = state) do
    state |> StartTask.async() |> Task.await()
  end

  @spec wait_for_stop(os_pid) :: nil
  defp wait_for_stop(os_pid) do
    if os_process_running?(os_pid) do
      Process.sleep(100)
      wait_for_stop(os_pid)
    end
  end

  @spec os_process_running?(os_pid) :: boolean
  def os_process_running?(os_pid) do
    case System.cmd("kill", ["-0", to_string(os_pid)], stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  end
end
