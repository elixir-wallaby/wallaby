defmodule Wallaby.Experimental.Chrome.Chromedriver do
  use GenServer

  # @external_resource "priv/run_phantom.sh"
  # @script_contents File.read! "priv/run_phantom.sh"

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def stop(server) do
    GenServer.stop(server)
  end

  def base_url(server) do
    GenServer.call(server, :base_url)
  end

  def init(_) do
    tcp_port = find_available_port()
    port = start_chromedriver(tcp_port)

    {:ok, %{running: false, port: port, base_url: "http://localhost:#{tcp_port}/"}}
  end

  def handle_call(:base_url, _from, %{base_url: base_url}=state) do
    {:reply, {:ok, base_url}, state}
  end

  def handle_info(msg, state) do
    IO.inspect(msg, label: "Chromedriver message")
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    IO.puts("terminating")
  end

  defp find_available_port() do
    {:ok, listen} = :gen_tcp.listen(0, [])
    {:ok, port} = :inet.port(listen)
    :gen_tcp.close(listen)
    port
  end

  defp start_chromedriver(tcp_port) do
    case System.find_executable("chromedriver") do
      chromedriver when not is_nil(chromedriver) ->
        Port.open({:spawn_executable, Path.absname("priv/run_command.sh", Application.app_dir(:wallaby))},
          [:binary, :stream, :use_stdio, :exit_status, args: args(chromedriver, tcp_port)])
      _ ->
        raise Wallaby.DependencyException, """
        Wallaby can't find chromedriver. Make sure you have chromedriver installed
        and included in your path.
        """
    end
  end

  defp args(chromedriver, port), do: [
      chromedriver,
      "--port=#{port}",
      "--verbose",
    ]
end
