defmodule Wallaby.Chrome.Chromedriver.ServerTest do
  use ExUnit.Case, async: true

  alias Wallaby.TestSupport.Chrome.ChromeTestScript
  alias Wallaby.TestSupport.TestScriptUtils
  alias Wallaby.TestSupport.TestWorkspace
  alias Wallaby.TestSupport.Utils

  alias Wallaby.Chrome
  alias Wallaby.Chrome.Chromedriver.Server

  @moduletag :capture_log

  test "starts up successfully before timeout" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_chrome_wrapper_script!()

    {:ok, pid} = Server.start_link(test_script_path, startup_timeout: :timer.seconds(10))
    base_url = Server.get_base_url(pid)

    :ok = Server.wait_until_ready(pid, :timer.seconds(10))

    assert_webdriver_api_ready(base_url)
  end

  test "crashes if the process doesn't become ready within timeout" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_chrome_wrapper_script!(startup_delay: 1_000)

    Process.flag(:trap_exit, true)

    {:ok, pid} = Server.start_link(test_script_path, startup_timeout: 200)
    base_url = Server.get_base_url(pid)

    assert_receive {:EXIT, ^pid, _}, 500

    refute_webdriver_api_ready(base_url)
  end

  test "wait_until_ready/1 blocks until server is ready for request" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_chrome_wrapper_script!(startup_delay: :timer.seconds(1))

    {:ok, pid} = Server.start_link(test_script_path)
    base_url = Server.get_base_url(pid)

    refute_webdriver_api_ready(base_url)

    :ok = Server.wait_until_ready(pid)

    assert_webdriver_api_ready(base_url)
  end

  test "wait_until_ready/1 returns {:error, :timeout} if it doesn't finish before timeout" do
    test_script_path =
      TestWorkspace.mkdir!()
      |> write_chrome_wrapper_script!(startup_delay: 1_000)

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
      |> write_chrome_wrapper_script!(startup_delay: 1_000)

    {:ok, pid} = Server.start_link(test_script_path)

    {initial_duration, _} = :timer.tc(fn -> :ok = Server.wait_until_ready(pid) end)
    {subsequent_duration, _} = :timer.tc(fn -> :ok = Server.wait_until_ready(pid) end)

    assert initial_duration > subsequent_duration
  end

  test "does not start when the unable to start chromedriver" do
    Process.flag(:trap_exit, true)

    {:ok, server} = Server.start_link("doesnotexist")

    assert_receive {:EXIT, ^server, {:exit_status, 127}}, 500
  end

  test "crashes when the wrapper script is killed" do
    Process.flag(:trap_exit, true)
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()
    {:ok, server} = Server.start_link(chromedriver_path)
    :ok = Server.wait_until_ready(server)
    wrapper_script_os_pid = Server.get_wrapper_script_os_pid(server)
    os_pid = Server.get_os_pid(server)

    kill_os_process(wrapper_script_os_pid)

    assert_receive {:EXIT, ^server, {:exit_status, _}}

    Utils.attempt_with_timeout(fn ->
      refute os_process_running?(wrapper_script_os_pid)
      refute os_process_running?(os_pid)
    end)
  end

  test "crashes when chromedriver is killed" do
    Process.flag(:trap_exit, true)
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()
    {:ok, server} = Server.start_link(chromedriver_path)

    :ok = Server.wait_until_ready(server)

    wrapper_script_os_pid = Server.get_wrapper_script_os_pid(server)
    os_pid = Server.get_os_pid(server)

    kill_os_process(os_pid)

    assert_receive {:EXIT, ^server, {:exit_status, _}}

    Utils.attempt_with_timeout(fn ->
      refute os_process_running?(wrapper_script_os_pid)
      refute os_process_running?(os_pid)
    end)
  end

  test "shuts down wrapper and chromedriver when server is stopped" do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()
    {:ok, server} = Server.start_link(chromedriver_path)
    wrapper_script_os_pid = Server.get_wrapper_script_os_pid(server)
    :ok = Server.wait_until_ready(server)
    os_pid = Server.get_os_pid(server)

    Server.stop(server)

    Utils.attempt_with_timeout(fn ->
      refute os_process_running?(wrapper_script_os_pid)
      refute os_process_running?(os_pid)
    end)
  end

  defp write_chrome_wrapper_script!(base_dir, opts \\ []) do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    chromedriver_path
    |> ChromeTestScript.build_chromedriver_wrapper_script(opts)
    |> TestScriptUtils.write_test_script!(base_dir)
  end

  defp assert_webdriver_api_ready(base_url) when is_binary(base_url) do
    assert {:ok, %WebDriverClient.ServerStatus{ready?: true}} =
             base_url |> build_webdriver_client_config() |> WebDriverClient.fetch_server_status()
  end

  defp refute_webdriver_api_ready(base_url) when is_binary(base_url) do
    assert {:error, %WebDriverClient.ConnectionError{reason: :econnrefused}} =
             base_url |> build_webdriver_client_config() |> WebDriverClient.fetch_server_status()
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

  defp build_webdriver_client_config(base_url) when is_binary(base_url) do
    WebDriverClient.Config.build(base_url, protocol: :w3c)
  end
end
