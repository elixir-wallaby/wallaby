defmodule Wallaby.Driver.ProcessWorkspace do
  @moduledoc false

  alias Wallaby.Driver.ProcessWorkspace.ServerSupervisor
  alias Wallaby.Driver.TemporaryPath

  # Creates a temporary workspace for a process that will
  # be cleaned up after the process goes down.
  @spec create(pid, String.t()) :: {:ok, String.t()}
  def create(process_pid, workspace_path \\ generate_workspace_path()) do
    {:ok, _} = ServerSupervisor.start_server(process_pid, workspace_path)
    {:ok, workspace_path}
  end

  defp generate_workspace_path do
    System.tmp_dir!()
    |> Path.join(tmp_dir_prefix())
    |> TemporaryPath.generate()
  end

  defp tmp_dir_prefix do
    Application.get_env(:wallaby, :tmp_dir_prefix, "")
  end
end
