defmodule Wallaby.Experimental.ChromeTest do
  use ExUnit.Case, async: false

  import Wallaby.SettingsTestHelpers
  import Wallaby.TestSupport.ApplicationControl
  import Wallaby.TestSupport.TestWorkspace

  alias Wallaby.TestSupport.Chrome.FakeChromedriverScript

  setup [
    :stop_wallaby,
    :set_to_chromedriver,
    :create_test_workspace
  ]

  @moduletag :capture_log

  test "starting wallaby with chromedriver calls the executable with the correct options", %{
    workspace_path: workspace_path
  } do
    ensure_setting_is_reset(:wallaby, :chromedriver)

    script_path = FakeChromedriverScript.write_test_script!(workspace_path)
    Application.put_env(:wallaby, :chromedriver, path: script_path)

    assert :ok = Application.start(:wallaby)

    # Application startup seems to call the FakeChromedriverScript async
    Process.sleep(500)

    {switches, []} =
      case FakeChromedriverScript.fetch_last_argv(script_path) do
        {:ok, argv} ->
          argv
          |> String.split()
          |> OptionParser.parse!(switches: [], allow_nonexistent_atoms: true)

        {:error, :not_found} ->
          flunk("Fake chromedriver script not called. (Script: #{script_path})")
      end

    assert {port, remaining_switches} = Keyword.pop(switches, :port)
    assert is_binary(port)

    assert remaining_switches == [log_level: "OFF"]
  end

  test "wallaby fails to start if chromedriver's version is < 2.30", %{
    workspace_path: workspace_path
  } do
    ensure_setting_is_reset(:wallaby, :chromedriver)

    script_path = FakeChromedriverScript.write_test_script!(workspace_path, version: "2.29")
    Application.put_env(:wallaby, :chromedriver, path: script_path)

    assert {:error, _} = Application.start(:wallaby)
  end
end
