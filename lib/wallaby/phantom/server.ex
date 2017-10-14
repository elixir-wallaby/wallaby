defmodule Wallaby.Phantom.Server do
  @moduledoc false
  use GenServer

  alias Wallaby.Driver.ExternalCommand
  alias Wallaby.Phantom.Server.ServerState

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

  def get_local_storage_dir(server) do
    GenServer.call(server, :get_local_storage_dir, :infinity)
  end

  def clear_local_storage(server) do
    GenServer.call(server, :clear_local_storage, :infinity)
  end

  def init(_) do
    state =
      ServerState.new()
      |> create_local_storage_dir()
      |> start_phantom()

    {:ok, state}
  end

  defp start_phantom(%ServerState{} = state) do
    phantom_port =
      state
      |> ServerState.external_command()
      |> open_port_with_wrapper_script()

    %ServerState{state | phantom_port: phantom_port}
  end

  @spec create_local_storage_dir(ServerState.t) :: ServerState.t
  defp create_local_storage_dir(%ServerState{} = state) do
    File.mkdir_p(state.local_storage_path)
    state
  end

  def handle_info({_port, {:data, output}}, %ServerState{running: false} = state) do
    if output =~ "running on port" do
      state = %{state | running: true}
      {:ok, base_url} = ServerState.fetch_base_url(state)
      Enum.each state.awaiting_url, &GenServer.reply(&1, base_url)
      {:noreply, %{state | awaiting_url: []}}
    else
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

  def handle_call(:get_local_storage_dir, _from, state) do
    {:reply, state.local_storage_path, state}
  end

  def handle_call(:clear_local_storage, _from, state) do
    result = File.rm_rf(state.local_storage_path)

    {:reply, result, state}
  end

  def terminate(_reason, state) do
    File.rm_rf(state.local_storage_path)
  end

  defp open_port_with_wrapper_script(%ExternalCommand{executable: executable, args: args}) do
    # Starts phantomjs using the run_phantom.sh wrapper script so phantomjs will
    # be shutdown when stdin closes and when the beam terminates unexpectedly.
    # When running as an escript, priv/run_phantom.sh will not be present so we
    # pipe the script contents into sh -s. Here is the basic command we are
    # running below:
    #
    #   <wrapper_script_contents > | sh -s phantomjs --arg-1 --arg-2
    #

    args = ["-s", executable] ++ args

    port = Port.open({:spawn_executable, System.find_executable("sh")},
            [:binary, :stream, :use_stdio, :exit_status, args: args])
    Port.command(port, @run_phantom_script_contents)
    port
  end
end
