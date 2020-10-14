defmodule Wallaby.Driver.ProcessWorkspace.ServerSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias Wallaby.Driver.ProcessWorkspace.Server

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_server(pid, String.t()) :: DynamicSupervisor.on_start_child()
  def start_server(process_pid, workspace_path) do
    DynamicSupervisor.start_child(__MODULE__, {Server, [process_pid, workspace_path]})
  end

  @impl DynamicSupervisor
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # def child_spec(_arg) do
  #   %{
  #     id: __MODULE__,
  #     start: {__MODULE__, :start_link, []},
  #     type: :supervisor
  #   }
  # end
end
