defmodule Wallaby.Integration.Phantom.StartingSessionsTest do
  use ExUnit.Case, async: false

  import Wallaby.SettingsTestHelpers
  import Wallaby.TestSupport.ApplicationControl
  import Wallaby.TestSupport.TestScriptUtils
  import Wallaby.TestSupport.TestWorkspace

  alias Wallaby.Phantom
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

  test "works with a path in the home directory" do
    workspace_path = "~/.wallaby-tmp-#{random_string()}"
    expanded_workspace_path = Path.expand(workspace_path)
    :ok = File.mkdir_p!(expanded_workspace_path)
    on_exit(fn -> File.rm_rf!(expanded_workspace_path) end)

    pool_size = 1
    {:ok, original_phantomjs_path} = Phantom.find_phantomjs_executable()

    expanded_test_script_path =
      original_phantomjs_path
      |> PhantomTestScript.build_wrapper_script()
      |> write_test_script!(expanded_workspace_path)

    non_expanded_test_script_path =
      Path.join(
        workspace_path,
        Path.basename(expanded_test_script_path)
      )

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, non_expanded_test_script_path)

    ensure_setting_is_reset(:wallaby, :pool_size)
    Application.put_env(:wallaby, :pool_size, pool_size)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()

    assert expanded_test_script_path |> PhantomTestScript.get_invocations() |> length() ==
             pool_size
  end

  test "fails to start when phantomjs path is configured incorrectly" do
    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, "this-really-should-not-exist-#{random_string()}")

    assert {:error, _} = Application.start(:wallaby)
  end

  defp random_string do
    0x100000000
    |> :rand.uniform()
    |> Integer.to_string(36)
    |> String.downcase()
  end
end
