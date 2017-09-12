defmodule Wallaby.Experimental.Chrome.Chromedriver do
  @moduledoc false
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def base_url() do
    GenServer.call(__MODULE__, :base_url)
  end

  @dialyzer {:nowarn_function, init: 1}
  def init(_) do
    tcp_port = find_available_port()
    port = start_chromedriver(tcp_port)

    {:ok, %{running: false, port: port, base_url: "http://localhost:#{tcp_port}/"}}
  end

  def handle_call(:base_url, _from, %{base_url: base_url} = state) do
    {:reply, {:ok, base_url}, state}
  end

  def handle_info(_msg, state) do
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

  @dialyzer {:nowarn_function, start_chromedriver: 1}
  defp start_chromedriver(tcp_port) do
    case System.find_executable("chromedriver") do
      chromedriver when not is_nil(chromedriver) ->
        Port.open({:spawn_executable, wrapper_script()},
          [:binary, :stream, :use_stdio, :exit_status, args: args(chromedriver, tcp_port)])
      _ ->
        {:error, :no_chromedriver}
    end
  end

  defp wrapper_script() do
    Path.absname("priv/run_command.sh", Application.app_dir(:wallaby))
  end


  defp args(chromedriver, port), do: [
      chromedriver,
      "--port=#{port}",
    ]
end
