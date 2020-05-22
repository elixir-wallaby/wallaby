defmodule Wallaby.Chrome.LoggerTest do
  use ExUnit.Case, async: false

  alias Wallaby.Chrome.Logger
  import ExUnit.CaptureIO
  alias Wallaby.SettingsTestHelpers

  describe "parse_log/1" do
    test "removes line numbers from the end of INFO logs" do
      fun = fn ->
        build_log(~s(http://localhost:52615/logs.html 13:14 "test"))
        |> Logger.parse_log()
      end

      assert capture_io(fun) == "test\n"
    end

    test "prints non-string data types" do
      fun = fn ->
        build_log(~s(http://localhost:52615/logs.html 13:14 1))
        |> Logger.parse_log()
      end

      assert capture_io(fun) == "1\n"

      fun = fn ->
        build_log(~s[http://localhost:52615/logs.html 13:14 Array(2)])
        |> Logger.parse_log()
      end

      assert capture_io(fun) == "Array(2)\n"
    end

    test "prints messages with embedded newlines" do
      fun = fn ->
        build_log(~s[http://localhost:52615/logs.html 13:14 "test\nlog"])
        |> Logger.parse_log()
      end

      assert capture_io(fun) == "\"test\nlog\"\n"
    end

    test "pretty prints json" do
      message =
        ~s(http://localhost:54579/logs.html 13:14 "{\"href\":\"http://localhost:54579/logs.html\",\"ancestorOrigins\":{}}")

      fun = fn ->
        message
        |> build_log
        |> Logger.parse_log()
      end

      assert capture_io(fun) ==
               "\n{\n  \"ancestorOrigins\": {},\n  \"href\": \"http://localhost:54579/logs.html\"\n}\n"
    end

    test "can be disabled" do
      SettingsTestHelpers.ensure_setting_is_reset(:wallaby, :js_logger)
      Application.put_env(:wallaby, :js_logger, nil)

      fun = fn ->
        "test log"
        |> build_log()
        |> Logger.parse_log()
      end

      assert capture_io(fun) == ""
    end
  end

  def build_log(msg) do
    %{"level" => "INFO", "source" => "console-api", "message" => msg}
  end
end
