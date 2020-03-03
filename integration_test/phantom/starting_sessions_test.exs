defmodule Wallaby.Integration.Phantom.StartingSessionsTest do
  use ExUnit.Case, async: false

  import Wallaby.SettingsTestHelpers
  import Wallaby.TestSupport.ApplicationControl
  import Wallaby.TestSupport.TestScriptUtils
  import Wallaby.TestSupport.TestWorkspace

  alias Wallaby.TestSupport.Phantom.PhantomTestScript

  @moduletag :capture_log

  setup [:restart_wallaby_on_exit!, :stop_wallaby, :create_test_workspace]

  test "works when phantomjs starts immediately", %{
    workspace_path: workspace_path
  } do
    test_script_path =
      Wallaby.phantomjs_path()
      |> PhantomTestScript.build_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()
  end

  test "starts a session with default args when none are configured", %{
    workspace_path: workspace_path
  } do
    original_phantomjs_path = Wallaby.phantomjs_path()

    test_script_path =
      original_phantomjs_path
      |> PhantomTestScript.build_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    ensure_setting_is_reset(:wallaby, :phantomjs_args)
    Application.delete_env(:wallaby, :phantomjs_args)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()

    for invocation <- PhantomTestScript.get_invocations(test_script_path) do
      assert {switches, [^original_phantomjs_path]} =
               invocation
               |> String.split()
               |> OptionParser.parse!(switches: [], allow_nonexistent_atoms: true)

      switches
      |> assert_switch(:webdriver, fn port -> String.to_integer(port) > 0 end)
      |> assert_switch(:local_storage_path, &File.dir?/1)
      |> assert_no_remaining_switches()
    end
  end

  test "starts a session with the configured arguments", %{workspace_path: workspace_path} do
    original_phantomjs_path = Wallaby.phantomjs_path()

    test_script_path =
      original_phantomjs_path
      |> PhantomTestScript.build_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    ensure_setting_is_reset(:wallaby, :phantomjs_args)

    Application.put_env(
      :wallaby,
      :phantomjs_args,
      "--webdriver-loglevel=DEBUG --output-encoding=UTF-8"
    )

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()

    for invocation <- PhantomTestScript.get_invocations(test_script_path) do
      assert {switches, [^original_phantomjs_path]} =
               invocation
               |> String.split()
               |> OptionParser.parse!(switches: [], allow_nonexistent_atoms: true)

      switches
      |> assert_switch(:webdriver, fn port -> String.to_integer(port) > 0 end)
      |> assert_switch(:local_storage_path, &File.dir?/1)
      |> assert_switch(:webdriver_loglevel, &match?("DEBUG", &1))
      |> assert_switch(:output_encoding, &match?("UTF-8", &1))
      |> assert_no_remaining_switches()
    end
  end

  test "starts one phantomjs instance per scheduler by default", %{workspace_path: workspace_path} do
    original_phantomjs_path = Wallaby.phantomjs_path()

    test_script_path =
      original_phantomjs_path
      |> PhantomTestScript.build_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    ensure_setting_is_reset(:wallaby, :pool_size)
    Application.delete_env(:wallaby, :pool_size)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()

    assert test_script_path |> PhantomTestScript.get_invocations() |> length() ==
             :erlang.system_info(:schedulers_online)
  end

  test "allows size of phantomjs instance pool to be configured", %{
    workspace_path: workspace_path
  } do
    desired_pool_size = 1
    original_phantomjs_path = Wallaby.phantomjs_path()

    test_script_path =
      original_phantomjs_path
      |> PhantomTestScript.build_wrapper_script()
      |> write_test_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    ensure_setting_is_reset(:wallaby, :pool_size)
    Application.put_env(:wallaby, :pool_size, desired_pool_size)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()

    assert ^desired_pool_size =
             test_script_path |> PhantomTestScript.get_invocations() |> length()
  end
end
