defmodule Wallaby.Phantom.ConfigureTest do
  use ExUnit.Case, async: false

  import Wallaby.SettingsTestHelpers

  describe "changing phantom path" do
    setup do
      ensure_setting_is_reset(:wallaby, :phantomjs)
    end

    test "the phantomjs path changes" do
      Application.put_env(:wallaby, :phantomjs, "test/path/phantomjs")
      assert Wallaby.phantomjs_path == "test/path/phantomjs"
    end

    test "updates the phantomjs command" do
      Application.put_env(:wallaby, :phantomjs, "test/path/phantomjs")
      assert "test/path/phantomjs" in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
    end
  end

  describe "adding phantom args" do
    setup do
      ensure_setting_is_reset(:wallaby, :phantomjs_args)
    end

    test "when args are an array" do
      options = [opt1, opt2] = ["--some-opt=value", "--other-opt"]

      Application.put_env(:wallaby, :phantomjs_args, options)
      assert opt1 in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
      assert opt2 in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
    end

    test "when args are in a single string separated by spaces" do
      options = [opt1, opt2] = ["--some-opt=value", "--other-opt"]

      Application.put_env(:wallaby, :phantomjs_args, Enum.join(options, " "))
      assert opt1 in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
      assert opt2 in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
    end
  end
end
