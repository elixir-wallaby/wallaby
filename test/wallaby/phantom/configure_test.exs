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

  describe "adding phantom args" do
    setup do
      old_env = Application.get_env(:wallaby, :phantomjs_args)
      context = %{old_env: old_env}

      on_exit fn ->
        reset_env(context)
      end

      {:ok, context}
    end

    defp reset_env(%{old_env: old_env}) do
      Application.put_env(:wallaby, :phantomjs_args, old_env)
    end

    test "updates the phantomjs command", context do
      options = [opt1, opt2] = ["--some-opt=value", "--other-opt"]

      Application.put_env(:wallaby, :phantomjs_args, Enum.join(options, " "))
      assert opt1 in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
      assert opt2 in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')

      reset_env(context)
      Application.put_env(:wallaby, :phantomjs_args, options)
      assert opt1 in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
      assert opt2 in Wallaby.Phantom.Server.script_args(1234, '/tmp/dir')
    end
  end
end
