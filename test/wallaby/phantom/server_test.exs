defmodule Wallaby.Phantom.ServerTest do
  use ExUnit.Case, async: true

  import Wallaby.TestSupport.TestScriptUtils

  alias Wallaby.Phantom
  alias Wallaby.Phantom.Server
  alias Wallaby.TestSupport.Phantom.PhantomTestScript
  alias Wallaby.TestSupport.TestWorkspace

  @moduletag :capture_log

  test "starts up successfully before timeout" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_phantom_wrapper_script!()

    {:ok, server} = Server.start_link(test_script_path, startup_timeout: :timer.seconds(10))
    base_url = Server.get_base_url(server)

    :ok = Server.wait_until_ready(server, :timer.seconds(10))

    assert_webdriver_api_ready(base_url)
  end

  test "crashes if the process doesn't become ready within timeout" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_phantom_wrapper_script!()

    Process.flag(:trap_exit, true)

    {:ok, server} = Server.start_link(test_script_path, startup_timeout: 200)
    base_url = Server.get_base_url(server)

    assert_receive {:EXIT, ^server, {%RuntimeError{}, _}}, 500

    refute_webdriver_api_ready(base_url)
  end

  test "wait_until_ready/1 blocks until server is ready for request" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_phantom_wrapper_script!(startup_delay: 500)

    {:ok, pid} = Server.start_link(test_script_path)
    base_url = Server.get_base_url(pid)

    refute_webdriver_api_ready(base_url)

    :ok = Server.wait_until_ready(pid)

    assert_webdriver_api_ready(base_url)
  end

  test "wait_until_ready/1 returns {:error, :timeout} if it doesn't finish before timeout" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_phantom_wrapper_script!(startup_delay: 200)

    {:ok, pid} = Server.start_link(test_script_path)
    base_url = Server.get_base_url(pid)

    assert {:error, :timeout} = Server.wait_until_ready(pid, 100)

    refute_webdriver_api_ready(base_url)

    assert :ok = Server.wait_until_ready(pid)

    assert_webdriver_api_ready(base_url)
  end

  test "wait_until_ready/1 returns immediately on subsequent calls" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_phantom_wrapper_script!(startup_delay: 200)

    {:ok, pid} = Server.start_link(test_script_path)

    {initial_duration, _} = :timer.tc(fn -> :ok = Server.wait_until_ready(pid) end)
    {subsequent_duration, _} = :timer.tc(fn -> :ok = Server.wait_until_ready(pid) end)

    assert initial_duration > subsequent_duration
  end

  test "separate servers do not share local storage" do
    {:ok, phantomjs_path} = Phantom.find_phantomjs_executable()
    {:ok, server} = Server.start_link(phantomjs_path)
    {:ok, other_server} = Server.start_link(phantomjs_path)

    local_storage = Server.get_local_storage_dir(server)
    other_local_storage = Server.get_local_storage_dir(other_server)

    # Remove the other directory before asserting so we can ensure deletion is successful
    File.rm_rf(other_local_storage)

    assert local_storage != other_local_storage
  end

  test "it clears local storage properly" do
    {:ok, phantomjs_path} = Phantom.find_phantomjs_executable()

    {:ok, server} = Server.start_link(phantomjs_path)
    local_storage = Server.get_local_storage_dir(server)
    assert File.exists?(local_storage)

    :ok = Server.clear_local_storage(server)
    refute File.exists?(local_storage)
  end

  test "it cleans up the local storage directory on stop" do
    {:ok, phantomjs_path} = Phantom.find_phantomjs_executable()

    {:ok, server} = Server.start_link(phantomjs_path)
    local_storage = Server.get_local_storage_dir(server)
    assert File.exists?(local_storage)

    Server.stop(server)
    Process.sleep(100)
    refute File.exists?(local_storage)
  end

  test "does not start when the unable to start phantom" do
    Process.flag(:trap_exit, true)

    {:ok, server} = Server.start_link("doesnotexist")

    assert_receive {:EXIT, ^server, {:exit_status, 127}}, 500
  end

  test "crashes when the wrapper script is killed" do
    Process.flag(:trap_exit, true)
    {:ok, phantomjs_path} = Phantom.find_phantomjs_executable()
    {:ok, server} = Server.start_link(phantomjs_path)
    :ok = Server.wait_until_ready(server)
    wrapper_script_os_pid = Server.get_wrapper_os_pid(server)
    os_pid = Server.get_os_pid(server)

    kill_os_process(wrapper_script_os_pid)

    assert_receive {:EXIT, ^server, {:exit_status, _}}
    refute os_process_running?(wrapper_script_os_pid)
    refute os_process_running?(os_pid)
  end

  test "crashes when phantom is killed" do
    Process.flag(:trap_exit, true)
    {:ok, phantomjs_path} = Phantom.find_phantomjs_executable()
    {:ok, server} = Server.start_link(phantomjs_path)

    :ok = Server.wait_until_ready(server)

    wrapper_script_os_pid = Server.get_wrapper_os_pid(server)
    os_pid = Server.get_os_pid(server)

    kill_os_process(os_pid)

    assert_receive {:EXIT, ^server, {:exit_status, _}}

    # Since the process isn't trapping exits, let things shut down async
    Process.sleep(100)
    refute os_process_running?(wrapper_script_os_pid)
    refute os_process_running?(os_pid)
  end

  test "shuts down wrapper and phantom when server is stopped" do
    {:ok, phantomjs_path} = Phantom.find_phantomjs_executable()
    {:ok, server} = Server.start_link(phantomjs_path)
    wrapper_os_pid = Server.get_wrapper_os_pid(server)
    :ok = Server.wait_until_ready(server)
    os_pid = Server.get_os_pid(server)

    Server.stop(server)

    refute os_process_running?(wrapper_os_pid)
    refute os_process_running?(os_pid)
  end

  defp kill_os_process(pid) when is_integer(pid) do
    {_, 0} = System.cmd("kill", [to_string(pid)])
    :ok
  end

  defp os_process_running?(os_pid) when is_integer(os_pid) do
    case System.cmd("kill", ["-0", to_string(os_pid)], stderr_to_stdout: true) do
      {_, 0} ->
        true

      _ ->
        false
    end
  end

  defp write_phantom_wrapper_script!(base_dir, opts \\ []) do
    {:ok, original_phantomjs_path} = Phantom.find_phantomjs_executable()

    original_phantomjs_path
    |> PhantomTestScript.build_wrapper_script(opts)
    |> write_test_script!(base_dir)
  end

  defp assert_webdriver_api_ready(base_url) when is_binary(base_url) do
    assert {:ok, %WebDriverClient.ServerStatus{ready?: true}} =
             base_url |> build_webdriver_client_config() |> WebDriverClient.fetch_server_status()
  end

  defp refute_webdriver_api_ready(base_url) when is_binary(base_url) do
    assert {:error, %WebDriverClient.ConnectionError{reason: :econnrefused}} =
             base_url |> build_webdriver_client_config() |> WebDriverClient.fetch_server_status()
  end

  defp build_webdriver_client_config(base_url) when is_binary(base_url) do
    WebDriverClient.Config.build(base_url, protocol: :jwp)
  end
end
