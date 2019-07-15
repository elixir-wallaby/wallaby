defmodule Wallaby.Phantom.Server.StartTask do
  @moduledoc false

  #
  # Task used to completely start phantomjs during the
  # Wallaby.Phantom.Server.init/1 callback. That way, when the init callback
  # finishes, the server is ready to use.
  #

  alias Wallaby.Driver.ExternalCommand
  alias Wallaby.Phantom.Server.ServerState

  @type os_pid :: non_neg_integer
  @type exit_code :: 0..255
  @type error_reason :: {:crashed, exit_code}

  @external_resource "priv/run_phantom.sh"
  @run_phantom_script_contents File.read! "priv/run_phantom.sh"

  def async(server_state) do
    Task.async(__MODULE__, :run, [self(), server_state])
  end

  @doc false
  @spec run(pid, ServerState.t) ::
    {:ok, ServerState.t} | {:error, error_reason}
  def run(server_pid, server_state) do
    case server_state |> setup_workspace() |> start_phantom() |> loop() do
      {:ok, server_state} ->
        # Transfers control of port over to the calling process.
        Port.connect(server_state.wrapper_script_port, server_pid)
        {:ok, server_state}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  @spec loop(ServerState.t) ::
    {:ok, ServerState.t} | {:error, error_reason}
  def loop(%ServerState{wrapper_script_port: port} = state) do
    receive do
      {^port, {:data, output}} ->
        case analyze_output(output) do
          :phantom_up ->
            {:ok, state}
          {:os_pid, os_pid} ->
            loop(%{state | phantom_os_pid: os_pid})
          _ ->
            loop(state)
        end
      {^port, {:exit_status, status}} ->
        {:error, {:crashed, status}}
    end
  end

  @spec setup_workspace(ServerState.t) :: ServerState.t
  defp setup_workspace(%ServerState{} = state) do
    state
    |> create_local_storage_dir()
    |> write_wrapper_script()
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
end
