defmodule Wallaby.Integration.Feature.AutomaticScreenshotTest do
  use ExUnit.Case

  alias ExUnit.CaptureIO

  describe "import Feature" do
    test "feature takes a screenshot on failure for each open wallaby session" do
      defmodule ImportFeature.FailureWithMultipleSessionsTest do
        use ExUnit.Case
        import Wallaby.Feature

        setup do
          Wallaby.SettingsTestHelpers.ensure_setting_is_reset(:wallaby, :screenshot_on_failure)
          Application.put_env(:wallaby, :screenshot_on_failure, true)

          :ok
        end

        feature "fails" do
          {:ok, _} = Wallaby.start_session()
          {:ok, _} = Wallaby.start_session()

          assert false
        end
      end

      configure_and_reload_on_exit(colors: [enabled: false])

      output =
        CaptureIO.capture_io(fn ->
          assert ExUnit.run() == %{failures: 1, skipped: 0, total: 1, excluded: 0}
        end)

      assert_one_feature_failed(output)
      assert screenshot_taken_count(output) == 2
    end
  end

  describe "use Feature" do
    test "feature takes a screenshot on failure for each open wallaby session" do
      defmodule UseFeature.FailureWithMultipleSessionsTest do
        use ExUnit.Case
        use Wallaby.Feature

        @sessions 2
        feature "fails", %{sessions: _sessions} do
          Wallaby.SettingsTestHelpers.ensure_setting_is_reset(:wallaby, :screenshot_on_failure)
          Application.put_env(:wallaby, :screenshot_on_failure, true)

          assert false
        end
      end

      configure_and_reload_on_exit(colors: [enabled: false])

      output =
        CaptureIO.capture_io(fn ->
          assert ExUnit.run() == %{failures: 1, skipped: 0, total: 1, excluded: 0}
        end)

      assert_one_feature_failed(output)
      assert screenshot_taken_count(output) == 2
    end
  end

  # ExUnit's CLIFormatter summary line changed format in Elixir 1.20.
  # Pre-1.20: "1 feature, 1 failure"
  # 1.20+:    "Result: 0/1 passed" / "Failed: 1 feature"
  defp assert_one_feature_failed(output) do
    if Version.match?(System.version(), ">= 1.20.0") do
      assert output =~ "\nResult: 0/1 passed\n"
      assert output =~ "\nFailed: 1 feature\n"
    else
      assert output =~ "\n1 feature, 1 failure\n"
    end
  end

  defp configure_and_reload_on_exit(opts) do
    old_opts = ExUnit.configuration()
    ExUnit.configure(opts)

    on_exit(fn -> ExUnit.configure(old_opts) end)
  end

  defp screenshot_taken_count(output) do
    ~r{- file:///}
    |> Regex.scan(output)
    |> length()
  end
end
