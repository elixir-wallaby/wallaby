defmodule Wallaby.Phantom.Server do
  @moduledoc false
  use GenServer

  alias Wallaby.Driver.Utils
  alias Wallaby.Driver.ProcessWorkspace
  alias Wallaby.Phantom.Server.ReadinessChecker

  @external_resource "priv/run_phantom.sh"
  @run_phantom_script_contents File.read!("priv/run_phantom.sh")

  @type os_pid :: non_neg_integer
  @type path :: String.t()
  @type server :: GenServer.server()
  @type port_number :: non_neg_integer()

  @default_startup_timeout :timer.seconds(10)

  @type start_link_opt :: {:startup_timeout, timeout(), phantomjs_args: [String.t()]}

  defmodule State do
    @moduledoc false

    @type port_number :: non_neg_integer()
    @type t :: %__MODULE__{
            port_number: port_number | nil,
            phantomjs_path: String.t(),
            phantomjs_user_provided_args: [String.t()],
            wrapper_script_port: port | nil,
            wrapper_script_os_pid: pid | nil,
            phantomjs_os_pid: pid | nil,
            workspace_path: String.t(),
            ready?: boolean,
            calls_awaiting_readiness: [GenServer.from()]
          }

    defstruct [
      :port_number,
      :phantomjs_path,
      :phantomjs_user_provided_args,
      :wrapper_script_port,
      :wrapper_script_os_pid,
      :phantomjs_os_pid,
      :workspace_path,
      ready?: false,
      calls_awaiting_readiness: []
    ]
  end

  @spec start_link(path, [start_link_opt]) :: GenServer.on_start()
  def start_link(phantomjs_path, opts) when is_binary(phantomjs_path) and is_list(opts) do
    {phantomjs_args, opts} = Keyword.pop_lazy(opts, :phantomjs_args, &phantomjs_args_from_env/0)

    GenServer.start_link(__MODULE__, {phantomjs_path, phantomjs_args, opts})
  end

  # Need to accept args as a keyword list a well, because poolboy's typespec
  # does not allow a regular list of args
  @spec start_link(path | Keyword.t()) :: GenServer.on_start()
  def start_link(path) when is_binary(path) do
    start_link(path, [])
  end

  def start_link(args) when is_list(args) do
    # Keyword.pop! isn't supported until Elixir 1.10 so just using
    # a private function
    {phantomjs_path, opts} = keyword_pop!(args, :phantomjs_path)

    start_link(phantomjs_path, opts)
  end

  @spec stop(server) :: :ok
  def stop(server) do
    GenServer.stop(server)
  end

  @spec wait_until_ready(server, timeout) :: :ok | {:error, :timeout}
  def wait_until_ready(server, timeout \\ 5000) do
    GenServer.call(server, :wait_until_ready, timeout)
  catch
    :exit, {:timeout, _} ->
      {:error, :timeout}
  end

  @spec get_base_url(server) :: String.t()
  def get_base_url(server) do
    GenServer.call(server, :get_base_url)
  end

  @spec get_wrapper_os_pid(server) :: os_pid
  def get_wrapper_os_pid(server) do
    GenServer.call(server, :get_wrapper_os_pid)
  end

  @spec get_os_pid(server) :: os_pid | nil
  def get_os_pid(server) do
    GenServer.call(server, :get_os_pid)
  end

  @spec get_local_storage_dir(server) :: String.t()
  def get_local_storage_dir(server) do
    GenServer.call(server, :get_local_storage_dir)
  end

  @spec clear_local_storage(server) :: :ok
  def clear_local_storage(server) do
    GenServer.call(server, :clear_local_storage)
  end

  @impl GenServer
  def init({phantomjs_path, phantomjs_args, opts}) do
    startup_timeout = Keyword.get(opts, :startup_timeout, @default_startup_timeout)
    Process.send_after(self(), :ensure_readiness, startup_timeout)

    state = %State{phantomjs_path: phantomjs_path, phantomjs_user_provided_args: phantomjs_args}

    {:ok, state, {:continue, :start_phantom}}
  end

  @impl GenServer
  def handle_continue(:start_phantom, state) do
    %State{
      phantomjs_path: phantomjs_path,
      phantomjs_user_provided_args: phantomjs_user_provided_args
    } = state

    {:ok, workspace_path} = ProcessWorkspace.create(self())
    create_local_storage_dir!(workspace_path)
    write_wrapper_script!(workspace_path)

    port_number = Utils.find_available_port()
    wrapper_script_path = wrapper_script_path(workspace_path)

    wrapper_script_port =
      Port.open({:spawn_executable, to_charlist(wrapper_script_path)}, [
        :binary,
        :stream,
        :use_stdio,
        :exit_status,
        :stderr_to_stdout,
        args:
          [
            phantomjs_path,
            "--webdriver=#{port_number}",
            "--local-storage-path=#{local_storage_path(workspace_path)}"
          ] ++ phantomjs_user_provided_args
      ])

    wrapper_script_os_pid =
      wrapper_script_port
      |> Port.info()
      |> Keyword.fetch!(:os_pid)

    check_readiness_async(port_number)

    state = %State{
      state
      | port_number: port_number,
        wrapper_script_port: wrapper_script_port,
        wrapper_script_os_pid: wrapper_script_os_pid,
        workspace_path: workspace_path
    }

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:wait_until_ready, from, %State{ready?: false} = state) do
    %State{calls_awaiting_readiness: calls_awaiting_readiness} = state

    {:noreply, %State{state | calls_awaiting_readiness: [from | calls_awaiting_readiness]}}
  end

  def handle_call(:wait_until_ready, _from, %State{ready?: true} = state) do
    {:reply, :ok, state}
  end

  def handle_call(:get_base_url, _, %State{port_number: port_number} = state) do
    {:reply, build_base_url(port_number), state}
  end

  def handle_call(:get_wrapper_os_pid, _, %State{wrapper_script_os_pid: wrapper_os_pid} = state) do
    {:reply, wrapper_os_pid, state}
  end

  def handle_call(:get_os_pid, _, %State{phantomjs_os_pid: phantom_os_pid} = state) do
    {:reply, phantom_os_pid, state}
  end

  def handle_call(:get_local_storage_dir, _from, %State{workspace_path: workspace_path} = state) do
    {:reply, local_storage_path(workspace_path), state}
  end

  def handle_call(:clear_local_storage, _from, %State{workspace_path: workspace_path} = state) do
    workspace_path |> local_storage_path() |> File.rm_rf!()

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:ensure_readiness, %State{ready?: true} = state), do: {:noreply, state}

  def handle_info(:ensure_readiness, %State{ready?: false}) do
    raise "phantomjs not ready after startup timeout"
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
        {:noreply, %State{state | phantomjs_os_pid: os_pid}}

      :unknown ->
        {:noreply, state}
    end
  end

  def handle_info({port, {:exit_status, status}}, %State{wrapper_script_port: port} = state) do
    {:stop, {:exit_status, status}, state}
  end

  @impl GenServer
  def terminate(_reason, %State{
        wrapper_script_port: wrapper_script_port,
        wrapper_script_os_pid: wrapper_script_os_pid
      })
      when is_port(wrapper_script_port) and is_integer(wrapper_script_os_pid) do
    Port.close(wrapper_script_port)
    wait_for_stop(wrapper_script_os_pid)
  rescue
    ArgumentError ->
      :ok
  end

  def terminate(_reason, _state), do: :ok

  @spec wait_for_stop(os_pid) :: nil
  defp wait_for_stop(os_pid) do
    if os_process_running?(os_pid) do
      Process.sleep(100)
      wait_for_stop(os_pid)
    end
  end

  @spec os_process_running?(os_pid) :: boolean
  defp os_process_running?(os_pid) do
    case System.cmd("kill", ["-0", to_string(os_pid)], stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  end

  defp check_readiness_async(port_number) do
    process_to_notify = self()
    base_url = build_base_url(port_number)

    Task.start_link(fn ->
      ReadinessChecker.wait_until_ready(base_url)
      send(process_to_notify, :ready)
    end)
  end

  @spec create_local_storage_dir!(String.t()) :: :ok | no_return
  defp create_local_storage_dir!(workspace_path) when is_binary(workspace_path) do
    workspace_path
    |> local_storage_path()
    |> File.mkdir_p!()
  end

  @spec write_wrapper_script!(String.t()) :: :ok | no_return
  defp write_wrapper_script!(workspace_path) do
    path = wrapper_script_path(workspace_path)

    File.write!(path, @run_phantom_script_contents)
    File.chmod!(path, 0o755)
  end

  @spec build_base_url(State.port_number()) :: String.t()
  defp build_base_url(port_number) when is_integer(port_number) do
    "http://localhost:#{port_number}/"
  end

  @spec local_storage_path(String.t()) :: String.t()
  defp local_storage_path(workspace_path) when is_binary(workspace_path) do
    Path.join(workspace_path, "local_storage")
  end

  @spec wrapper_script_path(String.t()) :: String.t()
  defp wrapper_script_path(workspace_path) when is_binary(workspace_path) do
    Path.join(workspace_path, "wrapper")
  end

  @spec phantomjs_args_from_env :: [String.t()] | String.t()
  defp phantomjs_args_from_env do
    Application.get_env(:wallaby, :phantomjs_args, "")
    |> normalize_phantomjs_args()
  end

  @spec normalize_phantomjs_args(String.t() | [String.t()]) :: [String.t()]
  defp normalize_phantomjs_args(args) when is_binary(args), do: String.split(args)

  defp normalize_phantomjs_args(args) when is_list(args), do: args

  @spec analyze_output(String.t()) :: {:os_pid, os_pid} | :unknown
  defp analyze_output(output) do
    case Regex.run(~r{PID: (\d+)}, output) do
      [_, os_pid] ->
        {:os_pid, String.to_integer(os_pid)}

      nil ->
        :unknown
    end
  end

  @spec keyword_pop!(keyword, atom) :: {term, keyword}
  defp keyword_pop!(keywords, key) when is_list(keywords) and is_atom(key) do
    case Keyword.fetch(keywords, key) do
      {:ok, value} -> {value, Keyword.delete(keywords, key)}
      :error -> raise KeyError, key: key, term: keywords
    end
  end
end
