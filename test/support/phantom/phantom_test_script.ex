defmodule Wallaby.TestSupport.Phantom.PhantomTestScript do
  @moduledoc """
  Generates scripts that allow testing wallaby's interaction with the
  phantomjs executable
  """

  @type test_script_opt :: {:startup_delay, non_neg_integer}
  @type path :: String.t()

  @doc """
  Builds a wrapper script around the given phantomjs executable
  that logs script invocations and allows for controlling startup delay.
  """
  @spec build_wrapper_script(String.t(), [test_script_opt]) :: String.t()
  def build_wrapper_script(phantom_path, opts \\ []) when is_list(opts) do
    startup_delay = Keyword.get(opts, :startup_delay, 0)

    """
    #!/bin/sh

    echo "#{phantom_path} $@" >> "$0-output"

    sleep #{startup_delay / 1000}

    exec #{phantom_path} $@
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
