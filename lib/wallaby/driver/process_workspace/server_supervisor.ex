defmodule Wallaby.Driver.ProcessWorkspace.ServerSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias Wallaby.Driver.ProcessWorkspace.Server

  @spec start_link :: Supervisor.on_start()
  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_server(pid, String.t()) :: DynamicSupervisor.on_start_child()
  def start_server(process_pid, workspace_path) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Server,
      start: {Server, :start_link, [process_pid, workspace_path]},
      restart: :transient
    })
  end

  @impl DynamicSupervisor
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
