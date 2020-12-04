defmodule Wallaby.Chrome.Chromedriver.Server do
  @moduledoc false
  use GenServer

  alias Wallaby.Chrome.Chromedriver.ReadinessChecker
  alias Wallaby.Driver.Utils

  defmodule State do
    @moduledoc false
    defstruct [
      :port_number,
      :chromedriver_path,
      :wrapper_script_port,
      :wrapper_script_os_pid,
      :chromedriver_os_pid,
      ready?: false,
      calls_awaiting_readiness: []
    ]

    @type os_pid :: non_neg_integer
    @type port_number :: non_neg_integer

    @type t :: %__MODULE__{
            port_number: port_number | nil,
            chromedriver_path: String.t(),
            wrapper_script_port: port | nil,
            wrapper_script_os_pid: os_pid | nil,
            chromedriver_os_pid: os_pid | nil,
            ready?: boolean(),
            calls_awaiting_readiness: [GenServer.from()]
          }
  end

  @type os_pid :: non_neg_integer
  @type server :: GenServer.server()
  @typep port_number :: non_neg_integer()

  @default_startup_timeout :timer.seconds(10)

  def child_spec(args) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, args}}
  end

  @type start_link_opt :: {:startup_timeout, timeout()} | GenServer.option()

  @spec start_link(String.t(), [start_link_opt]) :: GenServer.on_start()
  def start_link(chromedriver_path, opts \\ [])
      when is_binary(chromedriver_path) and is_list(opts) do
    {start_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, {chromedriver_path, opts}, start_opts)
  end

  @spec stop(server) :: :ok
  def stop(server) do
    GenServer.stop(server)
  end

  @spec get_base_url(server) :: String.t()
  def get_base_url(server) do
    server
    |> GenServer.call(:get_port_number)
    |> build_base_url()
  end

  @spec get_wrapper_script_os_pid(server) :: os_pid
  def get_wrapper_script_os_pid(server) do
    GenServer.call(server, :get_wrapper_script_os_pid)
  end

  @spec get_os_pid(server) :: os_pid | nil
  def get_os_pid(server) do
    GenServer.call(server, :get_os_pid)
  end

  @spec wait_until_ready(server, timeout()) :: :ok | {:error, :timeout}
  def wait_until_ready(server, timeout \\ 5000) do
    GenServer.call(server, :wait_until_ready, timeout)
  catch
    :exit, {:timeout, _} ->
      {:error, :timeout}
  end

  @impl true
  def init({chromedriver_path, opts}) do
    startup_timeout = Keyword.get(opts, :startup_timeout, @default_startup_timeout)
    Process.send_after(self(), :ensure_readiness, startup_timeout)

    {:ok, %State{chromedriver_path: chromedriver_path}, {:continue, :start_chromedriver}}
  end

  @impl true
  def handle_continue(:start_chromedriver, state) do
    %State{chromedriver_path: chromedriver_path} = state

    port_number = Utils.find_available_port()
    wrapper_script_port = open_chromedriver_port(chromedriver_path, port_number)

    wrapper_script_os_pid =
      wrapper_script_port
      |> Port.info()
      |> Keyword.fetch!(:os_pid)

    check_readiness_async(port_number)

    {:noreply,
     %State{
       state
       | port_number: port_number,
         wrapper_script_port: wrapper_script_port,
         wrapper_script_os_pid: wrapper_script_os_pid
     }}
  end

  @impl true
  def handle_info(:ensure_readiness, %State{ready?: true} = state), do: {:noreply, state}

  def handle_info(:ensure_readiness, %State{ready?: false}) do
    raise "chromedriver not ready after startup timeout"
  end

  def handle_info(:ready, state) do
    %State{calls_awaiting_readiness: calls_awaiting_readiness} = state

    for call <- calls_awaiting_readiness do
      GenServer.reply(call, :ok)
    end

    {:noreply, %State{state | calls_awaiting_readiness: [], ready?: true}}
  end

  def handle_info({port, {:data, output}}, %State{wrapper_script_port: port} = state) do
    case analyze_output(output) do
      {:os_pid, os_pid} ->
        {:noreply, %State{state | chromedriver_os_pid: os_pid}}

      :unknown ->
        {:noreply, state}
    end
  end

  def handle_info({port, {:exit_status, status}}, %State{wrapper_script_port: port} = state) do
    {:stop, {:exit_status, status}, state}
  end

  @impl true
  def handle_call(:get_port_number, _from, %State{port_number: port_number} = state) do
    {:reply, port_number, state}
  end

  def handle_call(:get_wrapper_script_os_pid, _, %State{wrapper_script_os_pid: os_pid} = state) do
    {:reply, os_pid, state}
  end

  def handle_call(:get_os_pid, _, %State{chromedriver_os_pid: chromedriver_os_pid} = state) do
    {:reply, chromedriver_os_pid, state}
  end

  def handle_call(:wait_until_ready, _from, %State{ready?: true} = state) do
    {:reply, :ok, state}
  end

  def handle_call(:wait_until_ready, from, %State{ready?: false} = state) do
    %State{calls_awaiting_readiness: calls_awaiting_readiness} = state
    {:noreply, %State{state | calls_awaiting_readiness: [from | calls_awaiting_readiness]}}
  end

  @spec open_chromedriver_port(String.t(), port_number) :: port
  defp open_chromedriver_port(chromedriver_path, port_number) when is_binary(chromedriver_path) do
    Port.open(
      {:spawn_executable, to_charlist(wrapper_script())},
      port_opts(chromedriver_path, port_number)
    )
  end

  @spec analyze_output(String.t()) :: {:os_pid, os_pid} | :unknown
  defp analyze_output(output) do
    case Regex.run(~r{PID: (\d+)}, output) do
      [_, os_pid] ->
        {:os_pid, String.to_integer(os_pid)}

      nil ->
        :unknown
    end
  end

  @spec wrapper_script :: String.t()
  defp wrapper_script do
    Path.absname("priv/run_command.sh", Application.app_dir(:wallaby))
  end

  defp args(chromedriver, port),
    do: [
      chromedriver,
      "--log-level=OFF",
      "--port=#{port}"
    ]

  defp port_opts(chromedriver, tcp_port),
    do: [
      :binary,
      :stream,
      :use_stdio,
      :stderr_to_stdout,
      :exit_status,
      args: args(chromedriver, tcp_port)
    ]

  defp check_readiness_async(port_number) do
    process_to_notify = self()
    base_url = build_base_url(port_number)

    Task.start_link(fn ->
      ReadinessChecker.wait_until_ready(base_url)
      send(process_to_notify, :ready)
    end)
  end

  @spec build_base_url(port_number) :: String.t()
  defp build_base_url(port_number) do
    "http://localhost:#{port_number}/"
  end
end
