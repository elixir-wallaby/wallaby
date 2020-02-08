defmodule Wallaby.TestSupport.Chrome.FakeChromedriverScript do
  @moduledoc """
  A fake chromedriver script that enables checking the argv options
  passed when process is started.

  This is very useful for integration style testing.
  """

  @type script_path :: String.t()
  @type test_script_opt :: {:version, String}

  @spec write_test_script!(String.t(), [test_script_opt]) :: script_path
  def write_test_script!(directory, opts \\ []) when is_list(opts) do
    script_name = "test_script-#{random_string()}"
    script_path = Path.join(directory, script_name)
    output_path = Path.join(directory, output_filename(script_name))
    contents = script_contents(output_path, opts)

    :ok = File.write(script_path, contents)
    :ok = File.chmod(script_path, 0o755)

    script_path
  end

  @spec fetch_last_argv(script_path) :: {:ok, String.t()} | {:error, :not_found}
  def fetch_last_argv(script_path) do
    directory = Path.dirname(script_path)
    script_name = Path.basename(script_path)
    output_path = Path.join(directory, output_filename(script_name))

    case File.read(output_path) do
      {:ok, contents} ->
        last_line =
          contents
          |> String.split("\n", trim: true)
          |> List.last()

        {:ok, last_line}

      {:error, :enoent} ->
        {:error, :not_found}
    end
  end

  defp script_contents(output_path, opts) do
    version = Keyword.get(opts, :version, "79.0.3945.36")

    """
    #!/bin/sh

    if [ "$1" = "--version" ]; then
    echo "ChromeDriver #{version}"
    else
    echo $@ >> #{output_path}
    fi
    """
  end

  defp output_filename(script_name) do
    "#{script_name}-output"
  end

  defp random_string do
    0x100000000
    |> :rand.uniform()
    |> Integer.to_string(36)
    |> String.downcase()
  end
end
