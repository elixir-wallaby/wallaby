defmodule Wallaby.TestSupport.TestWorkspace do
  @moduledoc """
  Test helpers that create temporary directory that exists
  for the lifetime of the test.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  alias Wallaby.Driver.TemporaryPath

  @deprecated "Use mkdir!/0 inside test instead"
  def create_test_workspace(_) do
    workspace_path = mkdir!()

    [workspace_path: workspace_path]
  end

  @doc """
  Create a directory that will be removed
  after the test exits.
  """
  @spec mkdir!(String.t()) :: String.t() | no_return
  def mkdir!(path \\ gen_tmp_path()) do
    :ok =
      path
      |> Path.expand()
      |> File.mkdir_p!()

    on_exit(fn ->
      File.rm_rf!(path)
    end)

    path
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
