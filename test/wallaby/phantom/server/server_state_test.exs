defmodule Wallaby.Phantom.Server.ServerStateTest do
  use ExUnit.Case
  import Wallaby.SettingsTestHelpers

  alias Wallaby.Phantom.Server.ServerState
  alias Wallaby.Driver.ExternalCommand

  describe "new/1" do
    setup do
      ensure_setting_is_reset(:wallaby, :phantomjs_args)
    end

    test "creates a new server state that's not running" do
      assert %ServerState{
               workspace_path: "/tmp",
               phantom_path: "my-phantom"
             } = ServerState.new("/tmp", "my-phantom")
    end

    test "creates a new server state with a prefilled port_number" do
      %ServerState{port_number: port_number} = build_server_state()

      assert is_integer(port_number)
    end

    test "allows overriding the port number" do
      assert %ServerState{port_number: 8080} = build_server_state(port_number: 8080)
    end

    test "defaults to reading phantom_args from env" do
      phantom_args = "--some-opt=value --other-opt"
      Application.put_env(:wallaby, :phantomjs_args, phantom_args)
      %ServerState{phantom_args: phantom_args} = build_server_state()

      assert "--some-opt=value" in phantom_args
      assert "--other-opt" in phantom_args
    end
  end

  describe "base_url/1" do
    test "returns the proper url" do
      state = [port_number: 8080] |> build_server_state()

      assert "http://localhost:8080/" = ServerState.base_url(state)
    end
  end

  describe "external_command/1" do
    test "with no phantom_args" do
      state = ServerState.new("/workspace", "my-phantomjs", port_number: 8000)

      assert %ExternalCommand{
               executable: "my-phantomjs",
               args: [
                 "--webdriver=8000",
                 "--local-storage-path=#{ServerState.local_storage_path(state)}"
               ]
             } == ServerState.external_command(state)
    end

    test "with phantom_args as a list" do
      state =
        ServerState.new("/workspace", "phantomjs", port_number: 8000, phantom_args: ["--debug"])

      assert %ExternalCommand{
               executable: "phantomjs",
               args: [
                 "--webdriver=8000",
                 "--local-storage-path=#{ServerState.local_storage_path(state)}",
                 "--debug"
               ]
             } == ServerState.external_command(state)
    end

    test "with phantom_args as a string" do
      state =
        ServerState.new("/workspace", "phantomjs",
          port_number: 8000,
          phantom_args: "--debug --hello=world"
        )

      assert %ExternalCommand{
               executable: "phantomjs",
               args: [
                 "--webdriver=8000",
                 "--local-storage-path=#{ServerState.local_storage_path(state)}",
                 "--debug",
                 "--hello=world"
               ]
             } == ServerState.external_command(state)
    end
  end

  describe "local_storage_path/1" do
    test "returns the workspace_path/local_storage" do
      state = ServerState.new("/tmp/wallaby", "phantomjs")

      assert "/tmp/wallaby/local_storage" == ServerState.local_storage_path(state)
    end
  end

  describe "wrapper_script_path/1" do
    test "returns the workspace_path/wrapper" do
      state = ServerState.new("/tmp/wallaby", "phantomjs")

      assert '/tmp/wallaby/wrapper' == ServerState.wrapper_script_path(state)
    end
  end

  defp build_server_state(params \\ []) do
    ServerState.new("/tmp", "/path/to/phantom", params)
  end
end
