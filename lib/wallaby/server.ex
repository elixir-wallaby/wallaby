defmodule Wallaby.Server do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def get_base_url(server) do
    GenServer.call(server, :get_base_url)
  end

  def init(_) do
    port = find_available_port
    command = "#{script_path} --webdriver=#{port}"

    Port.open({:spawn, command}, [:binary, :stream, :use_stdio, :exit_status])

    {:ok, %{running: false, awaiting_url: [], base_url: "http://localhost:#{port}/"}}
  end

  defp find_available_port do
    {:ok, listen} = :gen_tcp.listen(0, [])
    {:ok, port} = :inet.port(listen)
    :gen_tcp.close(listen)
    port
  end

  defp script_path do
    Path.absname("priv/run_phantom.sh", Application.app_dir(:wallaby))
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
end
