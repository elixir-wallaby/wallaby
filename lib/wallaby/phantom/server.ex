defmodule Wallaby.Phantom.Server do
  @moduledoc false
  use GenServer

  alias Wallaby.Driver.ExternalCommand
  alias Wallaby.Driver.ProcessWorkspace
  alias Wallaby.Phantom.Server.ServerState

  @type os_pid :: non_neg_integer

  @external_resource "priv/run_phantom.sh"
  @run_phantom_script_contents File.read! "priv/run_phantom.sh"

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def stop(server) do
    GenServer.stop(server)
  end

  def get_base_url(server) do
    GenServer.call(server, :get_base_url, :infinity)
  end

  @spec get_wrapper_os_pid(pid) :: os_pid
  def get_wrapper_os_pid(server) do
    GenServer.call(server, :get_wrapper_os_pid, :infinity)
  end

  @spec get_os_pid(pid) :: os_pid
  def get_os_pid(server) do
    GenServer.call(server, :get_os_pid, :infinity)
  end

  def get_local_storage_dir(server) do
    GenServer.call(server, :get_local_storage_dir, :infinity)
  end

  def clear_local_storage(server) do
    GenServer.call(server, :clear_local_storage, :infinity)
  end

  def init(_) do
    {:ok, workspace_path} = ProcessWorkspace.create(self())

    state =
      workspace_path
      |> ServerState.new()
      |> setup_workspace()
      |> start_phantom()

    {:ok, state}
  end

  @spec setup_workspace(ServerState.t) :: ServerState.t
  defp setup_workspace(%ServerState{} = state) do
    state
    |> create_local_storage_dir()
    |> write_wrapper_script()
  end

  @spec start_phantom(ServerState.t) :: ServerState.t
  defp start_phantom(%ServerState{} = state) do
    wrapper_script_port =
      state
      |> ServerState.external_command()
      |> open_port_with_wrapper_script(state)

    %ServerState{state |
      wrapper_script_port: wrapper_script_port,
      wrapper_script_os_pid: os_pid_from_port(wrapper_script_port)
    }
  end

  @spec create_local_storage_dir(ServerState.t) :: ServerState.t
  defp create_local_storage_dir(%ServerState{} = state) do
    state |> ServerState.local_storage_path |> File.mkdir_p!
    state
  end

  @spec write_wrapper_script(ServerState.t) :: ServerState.t
  defp write_wrapper_script(%ServerState{} = state) do
    path = ServerState.wrapper_script_path(state)

    File.write!(path, @run_phantom_script_contents)
    File.chmod!(path, 0o755)

    state
  end

  def handle_info({port, {:data, output}}, %ServerState{running: false, wrapper_script_port: port} = state) do
    case analyze_output(output) do
      :phantom_up ->
        state = %{state | running: true}
        {:ok, base_url} = ServerState.fetch_base_url(state)
        Enum.each state.awaiting_url, &GenServer.reply(&1, base_url)
        {:noreply, %{state | awaiting_url: []}}
      {:os_pid, os_pid} ->
        Enum.each state.awaiting_os_pid, &GenServer.reply(&1, os_pid)
        {:noreply, %{state | phantom_os_pid: os_pid, awaiting_os_pid: []}}
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({_port, {:exit_status, status}}, state) do
    {:stop, {:exit_status, status}, %{state | running: false}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_call(:get_base_url, from, state) do
    case ServerState.fetch_base_url(state) do
      {:ok, url} ->
        {:reply, url, state}
      {:error, :not_running} ->
        awaiting_url = [from | state.awaiting_url]
        {:noreply, %{state | awaiting_url: awaiting_url}}
    end
  end

  def handle_call(:get_wrapper_os_pid, _, %ServerState{wrapper_script_os_pid: wrapper_script_os_pid} = state) do
    {:reply, wrapper_script_os_pid, state}
  end

  def handle_call(:get_os_pid, from, %ServerState{phantom_os_pid: phantom_os_pid} = state) do
    if phantom_os_pid do
      {:reply, phantom_os_pid, state}
    else
      awaiting_os_pid = [from | state.awaiting_os_pid]
      {:noreply, %{state | awaiting_os_pid: awaiting_os_pid}}
    end
  end

  def handle_call(:get_local_storage_dir, _from, state) do
    {:reply, ServerState.local_storage_path(state), state}
  end

  def handle_call(:clear_local_storage, _from, state) do
    result =
      state |> ServerState.local_storage_path |> File.rm_rf

    {:reply, result, state}
  end

  def terminate(_reason, %ServerState{wrapper_script_port: wrapper_script_port, wrapper_script_os_pid: wrapper_script_os_pid}) do
    Port.close(wrapper_script_port)
    wait_for_stop(wrapper_script_os_pid)
  end

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

  @spec open_port_with_wrapper_script(ExternalCommand.t, ServerState.t) :: port
  defp open_port_with_wrapper_script(%ExternalCommand{executable: executable, args: args}, %ServerState{} = state) do
    Port.open({:spawn_executable, ServerState.wrapper_script_path(state)},
      [:binary, :stream, :use_stdio, :exit_status, :stderr_to_stdout,
        args: [executable] ++ args])
  end

  @spec os_pid_from_port(port) :: non_neg_integer
  defp os_pid_from_port(port) do
    %{os_pid: os_pid} = port |> Port.info |> Enum.into(%{})
    os_pid
  end

  @spec analyze_output(String.t) :: :phantom_up | {:os_pid, os_pid} | :unknown
  defp analyze_output(output) do
    cond do
      output =~ "running on port" ->
        :phantom_up
      result = Regex.run(~r{PID: (\d+)}, output) ->
        [_, os_pid] = result
        {:os_pid, String.to_integer(os_pid)}
      true ->
        :unknown
    end
  end
end
