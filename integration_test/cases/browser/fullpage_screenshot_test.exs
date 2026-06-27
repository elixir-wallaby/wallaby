defmodule Wallaby.Integration.Browser.FullpageScreenshotTest do
  use Wallaby.Integration.SessionCase, async: false

  import Wallaby.SettingsTestHelpers

  alias Wallaby.TestSupport.TestWorkspace

  setup %{session: session} do
    page =
      session
      |> visit("/long_page.html")

    screenshots_path = TestWorkspace.generate_temporary_path()
    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

    {:ok, page: page, screenshots_path: screenshots_path}
  end

  test "fullpage screenshot captures content beyond the viewport", %{page: page} do
    assert [viewport_path] =
             page
             |> take_screenshot(name: "viewport")
             |> Map.get(:screenshots)

    assert [fullpage_path] =
             page
             |> take_screenshot(name: "fullpage", full_page: true)
             |> Map.get(:screenshots)

    viewport_size = File.stat!(viewport_path).size
    fullpage_size = File.stat!(fullpage_path).size

    assert fullpage_size > viewport_size
  end

  test "full_page option defaults to false", %{page: page, screenshots_path: screenshots_path} do
    assert [path] =
             page
             |> take_screenshot(name: "default")
             |> Map.get(:screenshots)

    assert path |> Path.expand() |> File.exists?()
    assert Path.dirname(Path.expand(path)) == Path.expand(screenshots_path)
  end

  test "full_page can be combined with other options", %{page: page} do
    import ExUnit.CaptureIO

    output =
      capture_io(fn ->
        page
        |> take_screenshot(name: "fullpage_logged", full_page: true, log: true)
      end)

    assert output =~ "Screenshot taken, find it at"
    assert output =~ "fullpage_logged.png"
  end
end
