defmodule Wallaby.TestSupport.TestWorkspace do
  @moduledoc """
  Test helpers that create temporary directory that exists
  for the lifetime of the test.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  alias Wallaby.Driver.TemporaryPath

  def create_test_workspace(_) do
    workspace_path = gen_tmp_path()
    :ok = File.mkdir_p!(workspace_path)

    on_exit(fn ->
      File.rm_rf!(workspace_path)
    end)

    [workspace_path: workspace_path]
  end

  defp gen_tmp_path do
    base_dir =
      Path.join(
        System.tmp_dir!(),
        Application.get_env(:wallaby, :tmp_dir_prefix, "")
      )

    TemporaryPath.generate(base_dir)
  end
end
