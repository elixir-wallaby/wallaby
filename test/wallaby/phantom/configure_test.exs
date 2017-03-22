defmodule Wallaby.Phantom.ConfigrationTest do
  use ExUnit.Case, async: false

  describe "changing phantom path" do
    setup do
      old_env = Application.get_env(:wallaby, :phantomjs)
      Application.put_env(:wallaby, :phantomjs, "test/path/phantomjs")

      on_exit fn ->
        Application.put_env(:wallaby, :phantomjs, old_env)
      end
    end

    test "the phantomjs path changes" do
      assert Wallaby.phantomjs_path == "test/path/phantomjs"
    end

    test "updates the phantomjs command" do
      assert "test/path/phantomjs" in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
    end
  end
end
