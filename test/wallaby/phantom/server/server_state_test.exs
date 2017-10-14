defmodule Wallaby.Phantom.Server.ServerStateTest do
  use ExUnit.Case
  import Wallaby.SettingsTestHelpers

  alias Wallaby.Phantom.Server.ServerState
  alias Wallaby.Driver.ExternalCommand

  describe "new/1" do
    setup do
      ensure_setting_is_reset(:wallaby, :phantomjs)
      ensure_setting_is_reset(:wallaby, :phantomjs_args)
    end

    test "creates a new server state that's not running" do
      assert %ServerState{running: false} = ServerState.new()
    end

    test "creates a new server state with a prefilled port_number" do
      %ServerState{port_number: port_number} = ServerState.new()

      assert is_integer(port_number)
    end

    test "allows overriding the port number" do
      assert %ServerState{port_number: 8080} =
        ServerState.new(port_number: 8080)
    end

    test "creates a new server state with a local storage path" do
      %ServerState{local_storage_path: local_storage_path} = ServerState.new()

      assert local_storage_path =~ ~r(^#{System.tmp_dir!})
    end

    test "allows overriding the local storage path" do
      assert %ServerState{local_storage_path: "/srv/tmp"} =
        ServerState.new(local_storage_path: "/srv/tmp")
    end

    test "defaults to reading phantom_path from env" do
      Application.put_env(:wallaby, :phantomjs, "test/path/phantomjs")
      %ServerState{phantom_path: phantom_path} = ServerState.new

      assert phantom_path == "test/path/phantomjs"
    end

    test "defaults to reading phantom_args from env" do
      phantom_args = "--some-opt=value --other-opt"
      Application.put_env(:wallaby, :phantomjs_args, phantom_args)
      %ServerState{phantom_args: phantom_args} = ServerState.new

      assert "--some-opt=value" in phantom_args
      assert "--other-opt" in phantom_args
    end
  end

  describe "fetch_base_url/1" do
    test "when the server is running" do
      state = [port_number: 8080] |> ServerState.new() |> struct(running: true)

      assert {:ok, "http://localhost:8080/"} = ServerState.fetch_base_url(state)
    end

    test "when the server is not running" do
      state = [port_number: 8080] |> ServerState.new() |> struct(running: false)

      assert {:error, :not_running} = ServerState.fetch_base_url(state)
    end
  end

  describe "external_command/1" do
    test "with no phantom_args" do
      state = ServerState.new(
        phantom_path: "phantomjs",
        port_number: 8000,
        local_storage_path: "/srv/wallaby"
      )

      assert %ExternalCommand{
        executable: "phantomjs",
        args: [
          "--webdriver=8000",
          "--local-storage-path=/srv/wallaby"
        ]
      } = ServerState.external_command(state)
    end

    test "with phantom_args as a list" do
      state = ServerState.new(
        phantom_path: "phantomjs",
        port_number: 8000,
        local_storage_path: "/srv/wallaby",
        phantom_args: ["--debug"]
      )

      assert %ExternalCommand{
        executable: "phantomjs",
        args: [
          "--webdriver=8000",
          "--local-storage-path=/srv/wallaby",
          "--debug"
        ]
      } = ServerState.external_command(state)
    end

    test "with phantom_args as a string" do
      state = ServerState.new(
        phantom_path: "phantomjs",
        port_number: 8000,
        local_storage_path: "/srv/wallaby",
        phantom_args: "--debug --hello=world"
      )

      assert %ExternalCommand{
        executable: "phantomjs",
        args: [
          "--webdriver=8000",
          "--local-storage-path=/srv/wallaby",
          "--debug",
          "--hello=world",
        ]
      } = ServerState.external_command(state)
    end
  end
end
