defmodule Wallaby.TestSupport.TestScriptUtils do
  @moduledoc """
  Helper functions for working with webdriver test scripts
  """

  import ExUnit.Assertions

  @doc """
  Pops `switch` from `switches` so each switch value can be checked.

  Raises an `AssertionError` if `switch` key does not exist, or `fun` does not return true.
  """
  @spec assert_switch(keyword, atom, (term -> boolean)) :: keyword | no_return
  def assert_switch(switches, switch, fun \\ fn _ -> true end)
      when is_list(switches) and is_atom(switch) and is_function(fun, 1) do
    case Keyword.pop_first(switches, switch) do
      {nil, remaining_switches} ->
        flunk("""
        Switch #{inspect(switch)} not found

        Switches: #{inspect(remaining_switches, pretty: true)}
        """)

      {value, remaining_switches} ->
        assert fun.(value)

        remaining_switches
    end
  end

  @doc """
  Asserts all switches have been analyzed and removed from `switches`
  """
  @spec assert_no_remaining_switches(keyword) :: :ok | no_return
  def assert_no_remaining_switches(switches) when is_list(switches) do
    assert switches == [],
           """
           Expected all switches to have already been checked, but got:

           #{inspect(switches, pretty: true)}
           """
  end

  @doc """
  Writes `script_contents` into a test script in
  `base_directory` and makes it executable.
  """
  @spec write_test_script!(String.t(), String.t()) :: String.t() | no_return
  def write_test_script!(script_contents, base_directory) do
    script_name = "test_script-#{random_string()}"
    script_path = Path.join([base_directory, script_name])

    expanded_script_path = Path.expand(script_path)

    File.write!(expanded_script_path, script_contents)
    File.chmod!(expanded_script_path, 0o755)

    script_path
  end

  defp random_string do
    0x100000000
    |> :rand.uniform()
    |> Integer.to_string(36)
    |> String.downcase()
  end
end
