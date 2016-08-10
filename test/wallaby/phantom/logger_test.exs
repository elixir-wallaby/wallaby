defmodule Wallaby.Phantom.LoggerTest do
  use ExUnit.Case, async: true

  alias Wallaby.Phantom.Logger
  import ExUnit.CaptureIO

  describe "parse_log/1 INFO logs" do
    test "removes line numbers from the end of the log" do
      fun = fn ->
        build_log("test (:)")
        |> Logger.parse_log
      end

      assert capture_io(fun) == "test\n"

      fun = fn ->
        build_log("test (undefined:undefined)")
        |> Logger.parse_log
      end

      assert capture_io(fun) == "test\n"

      fun = fn ->
        build_log("test (1:3) (:)")
        |> Logger.parse_log
      end

      assert capture_io(fun) == "test (1:3)\n"
    end
  end

  def build_log(msg) do
    %{"level" => "INFO", "message" => msg}
  end
end
