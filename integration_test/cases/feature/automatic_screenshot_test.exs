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

      assert output =~ "\n1 feature, 1 failure\n"
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

      assert output =~ "\n1 feature, 1 failure\n"
      assert screenshot_taken_count(output) == 2
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
