defmodule Wallaby.TestSupport.TestWorkspace do
  @moduledoc """
  Test helpers that create temporary directory that exists
  for the lifetime of the test.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc """
  Create a directory that will be removed after the test exits.

  See `generate_temporary_path/1`
  """
  @spec mkdir!(String.t()) :: String.t() | no_return
  def mkdir!(path \\ default_tmp_path()) do
    path = generate_temporary_path(path)

    :ok = path |> Path.expand() |> File.mkdir_p!()

    path
  end

  @doc """
  Generates a temporary path (without creating the directory)
  that will be cleaned up after the test exits.

  ## Placeholders

  In order to not have filenames overlap, the following placeholders are supported
  * `%{random_string}` - This placeholder is replaced with a random string
  """
  def generate_temporary_path(path \\ default_tmp_path()) do
    path = replace_placeholders(path)

    on_exit(fn ->
      path
      |> Path.expand()
      |> File.rm_rf!()
    end)

    path
  end

  defp default_tmp_path do
    Path.join([
      System.tmp_dir!(),
      Application.get_env(:wallaby, :tmp_dir_prefix, ""),
      "test-workspace-%{random_string}"
    ])
  end

  defp replace_placeholders(path) do
    String.replace(path, "%{random_string}", random_string())
  end

  defp random_string do
    0x100000000
    |> :rand.uniform()
    |> Integer.to_string(36)
    |> String.downcase()
  end
end
