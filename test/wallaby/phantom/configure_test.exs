defmodule Wallaby.Phantom.ConfigrationTest do
  use ExUnit.Case, async: false

  describe "changing phantom path" do
    setup do
      Application.put_env(:wallaby, :phantomjs, "test/path/phantomjs")

      on_exit fn ->
        Application.put_env(:wallaby, :phantomjs, nil)
      end
    end

    test "the phantomjs path changes" do
      assert Wallaby.phantomjs_path == "test/path/phantomjs"
    end

    test "updates the phantomjs command" do
      assert Wallaby.Phantom.Server.phantomjs_command(1234, '/tmp/dir') =~ ~r/test\/path\/phantomjs/
    end
  end
end
