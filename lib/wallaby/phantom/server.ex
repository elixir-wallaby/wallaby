defmodule Wallaby.Phantom.Server do
  @moduledoc false
  use GenServer

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
    port = find_available_port()
    local_storage = tmp_local_storage()

    start_phantom(port, local_storage)

    {:ok, %{running: false, awaiting_url: [], base_url: "http://localhost:#{port}/", local_storage: local_storage}}
  end

  defp start_phantom(port, local_storage) do
    # Starts phantomjs using the run_phantom.sh wrapper script so phantomjs will
    # be shutdown when stdin closes and when the beam terminates unexpectedly.
    # When running as an escript, priv/run_phantom.sh will not be present so we
    # pipe the script contents into sh -s. Here is the basic command we are
    # running below:
    #
    #   <wrapper_script_contents > | sh -s phantomjs --arg-1 --arg-2
    #
    port = Port.open({:spawn_executable, System.find_executable("sh")},
            [:binary, :stream, :use_stdio, :exit_status, args: script_args(port, local_storage)])
    Port.command(port, @run_phantom_script_contents)
    port
  end

  def script_args(port, local_storage) do
    [
      "-s",
      phantomjs_path(),
      "--webdriver=#{port}",
      "--local-storage-path=#{local_storage}"
    ] ++ args(Application.get_env(:wallaby, :phantomjs_args, ""))
  end

  defp find_available_port do
    {:ok, listen} = :gen_tcp.listen(0, [])
    {:ok, port} = :inet.port(listen)
    :gen_tcp.close(listen)
    port
  end

  defp tmp_local_storage do
    dirname = 0x100000000 |> :rand.uniform |> Integer.to_string(36) |> String.downcase

    local_storage = Path.join(System.tmp_dir!, dirname)

    File.mkdir_p(local_storage)

    local_storage
  end

  defp phantomjs_path do
    Wallaby.phantomjs_path
  end

  defp args(phantomjs_args) when is_binary(phantomjs_args) do
    String.split(phantomjs_args)
  end

  defp args(phantomjs_args) when is_list(phantomjs_args) do
    phantomjs_args
  end

  def handle_info({_port, {:data, output}}, %{running: false} = state) do
    if output =~ "running on port" do
      Enum.each state.awaiting_url, &GenServer.reply(&1, state.base_url)
      {:noreply, %{state | running: true, awaiting_url: []}}
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

  def handle_call(:get_base_url, from, %{running: false} = state) do
    awaiting_url = [from|state.awaiting_url]
    {:noreply, %{state | awaiting_url: awaiting_url}}
  end

  def handle_call(:get_base_url, _from, state) do
    {:reply, state.base_url, state}
  end

  def handle_call(:get_local_storage_dir, _from, state) do
    {:reply, state.local_storage, state}
  end

  def handle_call(:clear_local_storage, _from, state) do
    result = File.rm_rf(state.local_storage)

    {:reply, result, state}
  end

  def terminate(_reason, state) do
    File.rm_rf(state.local_storage)
  end
end
