defmodule Wallaby.Experimental.Chrome.Chromedriver do
  @moduledoc false
  use GenServer

  alias Wallaby.Driver.Utils
  alias Wallaby.Experimental.Chrome

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def base_url do
    GenServer.call(__MODULE__, :base_url)
  end

  @dialyzer {:nowarn_function, init: 1}
  def init(_) do
    tcp_port = Utils.find_available_port()
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

  @dialyzer {:nowarn_function, start_chromedriver: 1}
  defp start_chromedriver(tcp_port) do
    with {:ok, chromedriver} <- Chrome.find_chromedriver_executable() do
      Port.open({:spawn_executable, wrapper_script()}, port_opts(chromedriver, tcp_port))
    else
      {:error, _message} -> {:error, :no_chromedriver}
    end
  end

  defp wrapper_script do
    Path.absname("priv/run_command.sh", Application.app_dir(:wallaby))
  end

  defp args(chromedriver, port), do: [
      chromedriver,
      "--log-level=OFF",
      "--port=#{port}",
    ]

  defp port_opts(chromedriver, tcp_port), do: [
    :binary,
    :stream,
    :use_stdio,
    :stderr_to_stdout,
    :exit_status,
    args: args(chromedriver, tcp_port),
  ]
end
