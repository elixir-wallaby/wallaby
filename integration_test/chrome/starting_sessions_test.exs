defmodule Wallaby.Integration.Chrome.StartingSessionsTest do
  use ExUnit.Case, async: false

  import Wallaby.SettingsTestHelpers
  import Wallaby.TestSupport.ApplicationControl
  import Wallaby.TestSupport.TestScriptUtils
  import Wallaby.TestSupport.TestWorkspace

  alias Wallaby.Experimental.Chrome
  alias Wallaby.TestSupport.Chrome.ChromeTestScript

  @moduletag :capture_log

  setup [:stop_wallaby, :create_test_workspace]

  test "works when chromedriver starts immediately", %{workspace_path: workspace_path} do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    test_script_path =
      chromedriver_path
      |> ChromeTestScript.build_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()
  end

  test "starting a session boots chromedriver with the default options", %{
    workspace_path: workspace_path
  } do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    test_script_path =
      chromedriver_path
      |> ChromeTestScript.build_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()

    assert [invocation] = ChromeTestScript.get_invocations(test_script_path) |> Enum.take(-1)

    assert {switches, [^chromedriver_path]} =
             invocation
             |> String.split()
             |> OptionParser.parse!(switches: [], allow_nonexistent_atoms: true)

    switches
    |> assert_switch(:port, fn port -> String.to_integer(port) > 0 end)
    |> assert_switch(:log_level, &match?("OFF", &1))
    |> assert_no_remaining_switches()
  end

  test "application does not start when chromedriver version < 2.30", %{
    workspace_path: workspace_path
  } do
    test_script_path =
      ChromeTestScript.build_version_mock_script(version: "2.29")
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert {:error, _} = Application.start(:wallaby)
  end

  test "application starts when chromedriver version >= 2.30", %{
    workspace_path: workspace_path
  } do
    test_script_path =
      ChromeTestScript.build_version_mock_script(version: "2.30")
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert :ok = Application.start(:wallaby)
  end
end
