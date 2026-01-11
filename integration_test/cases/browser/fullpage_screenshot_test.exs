defmodule Wallaby.Integration.Browser.FullpageScreenshotTest do
  use Wallaby.Integration.SessionCase, async: false

  import Wallaby.SettingsTestHelpers

  alias Wallaby.TestSupport.TestWorkspace

  setup %{session: session} do
    page =
      session
      |> visit("/")

    {:ok, page: page}
  end

  test "taking fullpage screenshots", %{page: page} do
    screenshots_path = TestWorkspace.generate_temporary_path()

    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

    [path] =
      page
      |> take_screenshot(name: "fullpage_test", full_page: true)
      |> Map.get(:screenshots)

    assert_in_directory(path, screenshots_path)
    assert Path.basename(path) == "fullpage_test.png"
    assert_file_exists(path)

    # Verify the file is a valid PNG by checking the PNG signature
    {:ok, file_content} = File.read(path)
    <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _rest::binary>> = file_content
  end

  test "fullpage screenshot option defaults to false", %{page: page} do
    screenshots_path = TestWorkspace.generate_temporary_path()

    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

    # Both of these should work the same way (viewport screenshot)
    [path1] = page |> take_screenshot(name: "test1") |> Map.get(:screenshots)
    [path2] = page |> take_screenshot(name: "test2", full_page: false) |> Map.get(:screenshots)

    assert_file_exists(path1)
    assert_file_exists(path2)
  end

  test "fullpage screenshot can be combined with log option", %{page: page} do
    screenshots_path = TestWorkspace.generate_temporary_path()

    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

    import ExUnit.CaptureIO

    output =
      capture_io(fn ->
        page
        |> take_screenshot(name: "fullpage_logged", full_page: true, log: true)
      end)

    assert output =~ "Screenshot taken, find it at"
    assert output =~ "fullpage_logged.png"
  end

  defp assert_in_directory(path, directory) do
    assert Path.expand(directory) == Path.expand(Path.dirname(path)), """
    Path is not in expected directory.

    path: #{inspect(path)}
    directory: #{inspect(directory)}
    """
  end

  defp assert_file_exists(path) do
    assert path |> Path.expand() |> File.exists?(), """
    File does not exist

    path: #{inspect(path)}
    """
  end
end
