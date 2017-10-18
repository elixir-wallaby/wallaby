defmodule Wallaby.Phantom.ServerTest do
  use ExUnit.Case, async: true

  alias Wallaby.Phantom.Server

  setup do
    {:ok, server} = Server.start_link([])
    {:ok, %{server: server}}
  end

  test "it can start a server", %{server: server}  do
    assert Server.get_base_url(server) =~ ~r"http://localhost:\d+/"
  end

  test "separate servers do not share local storage", %{server: server} do
    {:ok, other_server} = Server.start_link([])

    # TODO: Need to wait until servers are started so we don't get zombie
    # processes

    local_storage = Server.get_local_storage_dir(server)
    other_local_storage = Server.get_local_storage_dir(other_server)

    # Remove the other directory before asserting so we can ensure deletion is successful
    File.rm_rf(other_local_storage)

    assert local_storage != other_local_storage
  end

  test "it clears local storage properly", %{server: server} do
    local_storage = Server.get_local_storage_dir(server)
    assert File.exists?(local_storage)

    Server.clear_local_storage(server)
    refute File.exists?(local_storage)
  end

  #TODO figure out why this is leaving a stray phantom process around
  test "it cleans up the local storage directory on stop", %{server: server} do
    local_storage = Server.get_local_storage_dir(server)
    assert File.exists?(local_storage)

    Server.stop(server)
    Process.sleep(100)
    refute File.exists?(local_storage)
  end

  test "crashes when the wrapper script is killed", %{server: server} do
    Process.flag(:trap_exit, true)
    os_pid = Server.get_wrapper_os_pid(server)

    kill_os_process(os_pid)

    assert_receive {:EXIT, _, :normal}
  end

  test "crashes when phantom is killed", %{server: server} do
    Process.flag(:trap_exit, true)
    os_pid = Server.get_os_pid(server)

    kill_os_process(os_pid)

    assert_receive {:EXIT, _, :normal}
  end

  test "shuts down wrapper and phantom when server is stopped", %{server: server} do
    wrapper_os_pid = Server.get_wrapper_os_pid(server)
    os_pid = Server.get_os_pid(server)

    Server.stop(server)

    refute os_process_running?(wrapper_os_pid)
    refute os_process_running?(os_pid)
  end

  defp kill_os_process(pid) do
    {_, 0} = System.cmd("kill", [to_string(pid)])
    :ok
  end

  defp os_process_running?(os_pid) do
    case System.cmd("kill", ["-0", to_string(os_pid)], stderr_to_stdout: true) do
      {_, 0} ->
        true
      _ ->
        false
    end
  end
end
