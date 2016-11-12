defmodule Wallaby.Phantom.Server do
  use GenServer

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
    port = find_available_port
    local_storage = tmp_local_storage

    Port.open({:spawn, phantomjs_command(port, local_storage)}, [:binary, :stream, :use_stdio, :exit_status])

    {:ok, %{running: false, awaiting_url: [], base_url: "http://localhost:#{port}/", local_storage: local_storage}}
  end

  def phantomjs_command(port, local_storage) do
    "#{script_path} #{phantomjs_path} --webdriver=#{port} --local-storage-path=#{local_storage} #{args}"
  end

  defp find_available_port do
    {:ok, listen} = :gen_tcp.listen(0, [])
    {:ok, port} = :inet.port(listen)
    :gen_tcp.close(listen)
    port
  end

  defp tmp_local_storage do
    dirname = Integer.to_string(:rand.uniform(0x100000000), 36) |> String.downcase

    local_storage = Path.join(System.tmp_dir!, dirname)

    File.mkdir_p(local_storage)

    local_storage
  end

  defp script_path do
    Path.absname("priv/run_phantom.sh", Application.app_dir(:wallaby))
  end

  defp phantomjs_path do
    Wallaby.phantomjs_path
  end

  defp args do
    Application.get_env(:wallaby, :phantomjs_args, "")
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
