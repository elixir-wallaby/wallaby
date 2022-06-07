defmodule Wallaby.TestSupport.Chrome.ChromeTestScript do
  @moduledoc """
  Generates scripts that allow testing wallaby's interaction with the
  chromedriver executable
  """

  @type test_script_opt :: {:startup_delay, non_neg_integer}
  @type path :: String.t()

  @doc """
  Builds a wrapper script around the given chrome executable
  that logs script invocations and allows for controlling startup delay.
  """
  @spec build_chrome_wrapper_script(String.t(), [test_script_opt]) :: String.t()
  def build_chrome_wrapper_script(chrome_path, opts \\ []) when is_list(opts) do
    startup_delay = Keyword.get(opts, :startup_delay, 0)

    """
    #!/bin/sh

    echo "#{chrome_path} $@" >> "$0-output"

    if [ "$1" != "--version" ]; then
      sleep #{startup_delay / 1000}
    fi

    exec #{chrome_path} $@
    """
  end

  @type chrome_version_mock_script_opt :: {:version, String.t()}

  @doc """
  Builds a test script used to test version constraints
  """
  @spec build_chrome_version_mock_script([chrome_version_mock_script_opt]) :: String.t()
  def build_chrome_version_mock_script(opts) do
    version = Keyword.get(opts, :version, "79.0.3945.36")

    """
    #!/bin/sh

    if [ "$1" = "--version" ]; then
      echo "Google Chrome #{version}"
    fi
    """
  end

  @doc """
  Builds a wrapper script around the given chromedriver executable
  that logs script invocations and allows for controlling startup delay.
  """
  @spec build_chromedriver_wrapper_script(String.t(), [test_script_opt]) :: String.t()
  def build_chromedriver_wrapper_script(chromedriver_path, opts \\ []) when is_list(opts) do
    startup_delay = Keyword.get(opts, :startup_delay, 0)

    """
    #!/bin/sh

    echo "#{chromedriver_path} $@" >> "$0-output"

    if [ "$1" != "--version" ]; then
      sleep #{startup_delay / 1000}
    fi

    exec #{chromedriver_path} $@
    """
  end

  @type chromedriver_version_mock_script_opt :: {:version, String.t()}

  @doc """
  Builds a test script used to test version constraints
  """
  @spec build_chromedriver_version_mock_script([chromedriver_version_mock_script_opt]) ::
          String.t()
  def build_chromedriver_version_mock_script(opts) do
    version = Keyword.get(opts, :version, "79.0.3945.36")

    """
    #!/bin/sh

    if [ "$1" = "--version" ]; then
      echo "ChromeDriver #{version}"
    fi
    """
  end

  @doc """
  Returns a list of command-line invocations for a given script instance
  """
  @spec get_invocations(path) :: [String.t()]
  def get_invocations(script_path) when is_binary(script_path) do
    script_path
    |> output_path()
    |> Path.expand()
    |> File.read()
    |> case do
      {:ok, contents} ->
        String.split(contents, "\n", trim: true)

      {:error, :enoent} ->
        []
    end
  end

  @spec output_path(path) :: path
  defp output_path(script_path) do
    script_path <> "-output"
  end
end
