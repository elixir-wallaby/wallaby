defmodule Wallaby.Integration.Chrome.StartingSessionsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  import Wallaby.SettingsTestHelpers
  import Wallaby.TestSupport.ApplicationControl
  import Wallaby.TestSupport.TestScriptUtils
  import Wallaby.TestSupport.TestWorkspace

  alias Wallaby.Chrome
  alias Wallaby.TestSupport.Chrome.ChromeTestScript
  alias Wallaby.TestSupport.TestWorkspace

  @moduletag :capture_log

  setup [:restart_wallaby_on_exit!, :stop_wallaby]

  setup do
    [workspace_path: mkdir!()]
  end

  test "works when chromedriver starts immediately", %{workspace_path: workspace_path} do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    test_script_path =
      chromedriver_path
      |> ChromeTestScript.build_chromedriver_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, _session} = Wallaby.start_session()
  end

  test "starting a session boots chromedriver with the default options", %{
    workspace_path: workspace_path
  } do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    test_script_path =
      chromedriver_path
      |> ChromeTestScript.build_chromedriver_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, _session} = Wallaby.start_session()

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

  test "does not raise a connection refused error if chromedriver is slow to startup" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_chrome_wrapper_script!(startup_delay: :timer.seconds(1))

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, _session} = Wallaby.start_session()
  end

  test "raises a RuntimeError if chromedriver isn't ready before the startup timeout" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_chrome_wrapper_script!(startup_delay: :timer.seconds(12))

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert :ok = Application.start(:wallaby)

    assert_raise RuntimeError, ~r/timeout waiting for chromedriver to be ready/i, fn ->
      Wallaby.start_session(readiness_timeout: 500)
    end
  end

  test "application does not start when chromedriver version < 2.30", %{
    workspace_path: workspace_path
  } do
    test_script_path =
      ChromeTestScript.build_chromedriver_version_mock_script(version: "2.29")
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert {:error, _} = Application.start(:wallaby)
  end

  test "application starts when chromedriver version >= 2.30", %{workspace_path: workspace_path} do
    chromedriver_test_script_path =
      ChromeTestScript.build_chromedriver_version_mock_script(version: "2.30")
      |> write_test_script!(workspace_path)

    chrome_test_script_path =
      ChromeTestScript.build_chrome_version_mock_script(version: "2.30")
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: chromedriver_test_script_path)
    Application.put_env(:wallaby, :chromedriver, binary: chrome_test_script_path)

    log =
      capture_io(:stderr, fn ->
        assert :ok == Application.start(:wallaby)
      end)

    assert log =~ "Looks like you're trying to run Wallaby with a mismatched version of Chrome"
  end

  test "application does not start when chrome version != chromedriver version", %{
    workspace_path: workspace_path
  } do
    chromedriver_test_script_path =
      ChromeTestScript.build_chromedriver_version_mock_script(version: "99.0.3945.36")
      |> write_test_script!(workspace_path)

    chrome_test_script_path =
      ChromeTestScript.build_chrome_version_mock_script(version: "101.0.3945.36")
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: chromedriver_test_script_path)
    Application.put_env(:wallaby, :chromedriver, binary: chrome_test_script_path)

    log =
      capture_io(:stderr, fn ->
        assert :ok == Application.start(:wallaby)
      end)

    assert log =~ "Looks like you're trying to run Wallaby with a mismatched version of Chrome"
  end

  test "works with a path in the home directory" do
    test_script_path =
      "~/.wallaby-tmp-%{random_string}"
      |> TestWorkspace.mkdir!()
      |> write_chrome_wrapper_script!()

    ensure_setting_is_reset(:wallaby, :chromedriver)
    Application.put_env(:wallaby, :chromedriver, path: test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, _session} = Wallaby.start_session()

    assert test_script_path |> ChromeTestScript.get_invocations() |> Enum.any?()
  end

  test "fails to start when chromedriver path is configured incorrectly" do
    ensure_setting_is_reset(:wallaby, :chromedriver)

    Application.put_env(:wallaby, :chromedriver, path: "this-really-should-not-exist")

    assert {:error, _} = Application.start(:wallaby)
  end

  defp write_chrome_wrapper_script!(base_dir, opts \\ []) do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    chromedriver_path
    |> ChromeTestScript.build_chromedriver_wrapper_script(opts)
    |> write_test_script!(base_dir)
  end
end
