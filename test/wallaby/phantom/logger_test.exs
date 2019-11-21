defmodule Wallaby.Phantom.LoggerTest do
  use ExUnit.Case, async: false

  alias Wallaby.Phantom.Logger
  import ExUnit.CaptureIO

  describe "parse_log/1" do
    test "removes line numbers from the end of INFO logs" do
      fun = fn ->
        build_log("test (:)")
        |> Logger.parse_log()
      end

      assert capture_io(fun) == "test\n"

      fun = fn ->
        build_log("test (undefined:undefined)")
        |> Logger.parse_log()
      end

      assert capture_io(fun) == "test\n"

      fun = fn ->
        build_log("test (1:3) (:)")
        |> Logger.parse_log()
      end

      assert capture_io(fun) == "test (1:3)\n"
    end

    test "can be disabled" do
      Application.put_env(:wallaby, :js_logger, nil)

      fun = fn ->
        "test log"
        |> build_log()
        |> Logger.parse_log()
      end

      assert capture_io(fun) == ""

      Application.put_env(:wallaby, :js_logger, :stdio)
    end
  end

  def build_log(msg) do
    %{"level" => "INFO", "message" => msg}
  end
end
