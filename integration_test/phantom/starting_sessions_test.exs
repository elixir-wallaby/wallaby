defmodule Wallaby.Integration.Phantom.StartingSessionsTest do
  use ExUnit.Case, async: false

  import Wallaby.SettingsTestHelpers
  import Wallaby.TestSupport.ApplicationControl
  import Wallaby.TestSupport.TestScriptUtils
  import Wallaby.TestSupport.TestWorkspace

  alias Wallaby.Phantom
  alias Wallaby.TestSupport.Phantom.PhantomTestScript
  alias Wallaby.TestSupport.TestWorkspace

  @moduletag :capture_log

  setup [:restart_wallaby_on_exit!, :stop_wallaby, :create_test_workspace]

  test "works when phantomjs starts immediately", %{
    workspace_path: workspace_path
  } do
    test_script_path = write_phantom_wrapper_script!(workspace_path)

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()
  end

  test "works when phantomjs starts slowly" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_phantom_wrapper_script!(startup_delay: 2_000)

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()
  end

  test "raises a RuntimeError if phantomjs isn't ready before startup timeout" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_phantom_wrapper_script!(startup_delay: 10_000)

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    assert :ok = Application.start(:wallaby)

    readiness_timeout = 500

    assert_takes(readiness_timeout, 100, fn ->
      assert_raise RuntimeError, ~r/timeout waiting for phantomjs to be ready/i, fn ->
        Wallaby.start_session(readiness_timeout: readiness_timeout)
      end
    end)
  end

  test "starts a session with default args when none are configured", %{
    workspace_path: workspace_path
  } do
    {:ok, original_phantomjs_path} = Phantom.find_phantomjs_executable()
    test_script_path = write_phantom_wrapper_script!(workspace_path)

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
    {:ok, original_phantomjs_path} = Phantom.find_phantomjs_executable()
    test_script_path = write_phantom_wrapper_script!(workspace_path)

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
    test_script_path = write_phantom_wrapper_script!(workspace_path)

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
    test_script_path = write_phantom_wrapper_script!(workspace_path)

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
    test_script_path =
      "~/.wallaby-tmp-%{random_string}"
      |> TestWorkspace.mkdir!()
      |> write_phantom_wrapper_script!()

    pool_size = 1

    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, test_script_path)

    ensure_setting_is_reset(:wallaby, :pool_size)
    Application.put_env(:wallaby, :pool_size, pool_size)

    assert :ok = Application.start(:wallaby)

    assert {:ok, session} = Wallaby.start_session()

    assert test_script_path |> PhantomTestScript.get_invocations() |> length() == pool_size
  end

  test "fails to start when phantomjs path is configured incorrectly" do
    ensure_setting_is_reset(:wallaby, :phantomjs)
    Application.put_env(:wallaby, :phantomjs, "this-really-should-not-exist")

    assert {:error, _} = Application.start(:wallaby)
  end

  defp assert_takes(min_ms, max_additional_ms, fun)
       when is_integer(min_ms) and is_integer(max_additional_ms) and is_function(fun, 0) do
    duration_ms = :timer.tc(fun) |> elem(0) |> Kernel./(1000)
    max_ms = min_ms + max_additional_ms

    assert duration_ms >= min_ms && duration_ms <= max_ms, """
    expected duration to be >= #{inspect(min_ms)} and <= #{inspect(max_ms)}

    duration (ms): #{inspect(duration_ms)}
    """
  end

  defp write_phantom_wrapper_script!(base_dir, opts \\ []) do
    {:ok, original_phantomjs_path} = Phantom.find_phantomjs_executable()

    original_phantomjs_path
    |> PhantomTestScript.build_wrapper_script(opts)
    |> write_test_script!(base_dir)
  end
end
