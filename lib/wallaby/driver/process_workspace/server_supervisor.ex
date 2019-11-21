defmodule Wallaby.Driver.ProcessWorkspace.ServerSupervisor do
  @moduledoc false

  use Supervisor

  alias Wallaby.Driver.ProcessWorkspace.Server

  @spec start_link :: Supervisor.on_start()
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_server(pid, String.t()) :: Supervisor.on_start_child()
  def start_server(process_pid, workspace_path) do
    Supervisor.start_child(__MODULE__, [process_pid, workspace_path])
  end

  @impl Supervisor
  def init([]) do
    children = [worker(Server, [], restart: :transient)]

    supervise(children, strategy: :simple_one_for_one)
  end
end
