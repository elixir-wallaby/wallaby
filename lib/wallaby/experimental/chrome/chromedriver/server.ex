defmodule Wallaby.Experimental.Chrome.Chromedriver.Server do
  @moduledoc false
  use GenServer

  alias Wallaby.Driver.Utils
  alias Wallaby.Experimental.Chrome.Chromedriver.ReadinessChecker

  defmodule State do
    @moduledoc false
    defstruct [:port_number, :chromedriver_path, ready?: false, calls_awaiting_readiness: []]

    @type port_number :: non_neg_integer

    @type t :: %__MODULE__{
            port_number: port_number | nil,
            chromedriver_path: String.t(),
            ready?: boolean(),
            calls_awaiting_readiness: [GenServer.from()]
          }
  end

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

  @spec get_base_url(server) :: String.t()
  def get_base_url(server) do
    server
    |> GenServer.call(:get_port_number)
    |> build_base_url()
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

    {:ok, %State{chromedriver_path: chromedriver_path}, {:continue, nil}}
  end

  @impl true
  def handle_continue(_, state) do
    %State{chromedriver_path: chromedriver_path} = state

    port_number = Utils.find_available_port()
    open_chromedriver_port(chromedriver_path, port_number)

    check_readiness_async(port_number)

    {:noreply, %State{state | port_number: port_number}}
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

  @impl true
  def handle_call(:get_port_number, _from, %State{port_number: port_number} = state) do
    {:reply, port_number, state}
  end

  def handle_call(:wait_until_ready, _from, %State{ready?: true} = state) do
    {:reply, :ok, state}
  end

  def handle_call(:wait_until_ready, from, %State{ready?: false} = state) do
    %State{calls_awaiting_readiness: calls_awaiting_readiness} = state
    {:noreply, %State{state | calls_awaiting_readiness: [from | calls_awaiting_readiness]}}
  end

  @spec open_chromedriver_port(String.t(), port_number) :: port
  def open_chromedriver_port(chromedriver_path, port_number) when is_binary(chromedriver_path) do
    Port.open(
      {:spawn_executable, to_charlist(wrapper_script())},
      port_opts(chromedriver_path, port_number)
    )
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

    base_url = "http://localhost:#{port_number}"

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
