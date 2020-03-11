defmodule Wallaby.Experimental.Chrome.Chromedriver.ServerTest do
  use ExUnit.Case, async: true

  alias Wallaby.TestSupport.Chrome.ChromeTestScript
  alias Wallaby.TestSupport.TestScriptUtils
  alias Wallaby.TestSupport.TestWorkspace

  alias Wallaby.Experimental.Chrome
  alias Wallaby.Experimental.Chrome.Chromedriver.Server

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

  defp write_chrome_wrapper_script!(base_dir, opts \\ []) do
    {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

    chromedriver_path
    |> ChromeTestScript.build_wrapper_script(opts)
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

  defp build_webdriver_client_config(base_url) when is_binary(base_url) do
    WebDriverClient.Config.build(base_url, protocol: :w3c)
  end
end
