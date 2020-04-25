defmodule Wallaby.Integration.Browser.ScreenshotTest do
  use Wallaby.Integration.SessionCase, async: false

  import ExUnit.CaptureIO
  import Wallaby.SettingsTestHelpers

  alias Wallaby.TestSupport.TestWorkspace

  setup %{session: session} do
    page =
      session
      |> visit("/")

    {:ok, page: page}
  end

  @default_screenshots_path Path.join([File.cwd!(), "screenshots"])

  test "taking screenshots with default settings", %{page: page} do
    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.delete_env(:wallaby, :screenshot_dir)

    on_exit(fn -> File.rm_rf!(@default_screenshots_path) end)

    element =
      page
      |> take_screenshot
      |> find(Query.css("#header"))
      |> take_screenshot

    parent_screenshots =
      element
      |> Map.get(:parent)
      |> Map.get(:screenshots)

    element_screenshots =
      element
      |> Map.get(:screenshots)

    assert Enum.count(element_screenshots) == 1
    assert Enum.count(parent_screenshots) == 1

    Enum.each(element_screenshots ++ parent_screenshots, fn path ->
      assert_path_type(path, :absolute)
      assert_in_directory(path, @default_screenshots_path)
      assert_file_exists(path)
    end)
  end

  test "users can specify the screenshot directory with a relative path", %{page: page} do
    screenshots_path = TestWorkspace.generate_temporary_path(".tmp-shots-%{random_string}")

    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

    screenshots =
      page
      |> take_screenshot
      |> Map.get(:screenshots)

    assert screenshots |> Enum.count() == 1

    Enum.each(screenshots, fn path ->
      assert_path_type(path, :relative)
      assert_in_directory(path, screenshots_path)
      assert_file_exists(path)
    end)
  end

  test "users can specify the screenshot directory relative to their home directory", %{
    page: page
  } do
    screenshots_path =
      TestWorkspace.generate_temporary_path("~/.test-wallaby-screenshots-%{random_string}")

    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

    screenshots =
      page
      |> take_screenshot()
      |> Map.get(:screenshots)

    assert screenshots |> Enum.count() == 1

    Enum.each(screenshots, fn path ->
      assert_path_type(path, :relative)
      assert_in_directory(path, screenshots_path)
      assert_file_exists(path)
    end)
  end

  test "users can specify the screenshot directory with an absolute path", %{page: page} do
    screenshots_path = TestWorkspace.generate_temporary_path()

    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

    screenshots =
      page
      |> take_screenshot
      |> Map.get(:screenshots)

    assert screenshots |> Enum.count() == 1

    Enum.each(screenshots, fn path ->
      assert_path_type(path, :absolute)
      assert_in_directory(path, screenshots_path)
      assert_file_exists(path)
    end)
  end

  test "users can specify the screenshot name", %{page: page} do
    screenshots_path = TestWorkspace.generate_temporary_path()

    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

    [path] =
      page
      |> take_screenshot(name: "some_page")
      |> Map.get(:screenshots)

    assert_in_directory(path, screenshots_path)
    assert Path.basename(path) == "some_page.png"
    assert_file_exists(path)
  end

  describe "logging" do
    test "does not log by default", %{page: page} do
      screenshots_path = TestWorkspace.generate_temporary_path()

      ensure_setting_is_reset(:wallaby, :screenshot_dir)
      Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

      output = capture_io(fn -> take_screenshot(page) end)

      assert extract_screenshot_urls(output) == []
    end

    test "logs work with the default screenshot dir", %{page: page} do
      ensure_setting_is_reset(:wallaby, :screenshot_dir)
      Application.delete_env(:wallaby, :screenshot_dir)

      output = capture_io(fn -> take_screenshot(page, log: true) end)

      assert [screenshot_path] =
               output
               |> extract_screenshot_urls()
               |> Enum.map(&path_from_file_url!/1)

      assert_path_type(screenshot_path, :absolute)
      assert_in_directory(screenshot_path, @default_screenshots_path)
      assert_file_exists(screenshot_path)
    end

    test "logs file url when the sets the screenshot_dir to a relative path", %{page: page} do
      screenshots_path = TestWorkspace.generate_temporary_path(".tmp-shots-%{random_string}")

      ensure_setting_is_reset(:wallaby, :screenshot_dir)
      Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

      output = capture_io(fn -> take_screenshot(page, log: true) end)

      assert [screenshot_path] =
               output
               |> extract_screenshot_urls()
               |> Enum.map(&path_from_file_url!/1)

      assert_path_type(screenshot_path, :absolute)
      assert_in_directory(screenshot_path, screenshots_path)
      assert_file_exists(screenshot_path)
    end

    test "logs file url when the sets the screenshot_dir to an absolute path", %{page: page} do
      screenshots_path = TestWorkspace.generate_temporary_path()

      ensure_setting_is_reset(:wallaby, :screenshot_dir)
      Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

      output = capture_io(fn -> take_screenshot(page, log: true) end)

      assert [screenshot_path] =
               output
               |> extract_screenshot_urls()
               |> Enum.map(&path_from_file_url!/1)

      assert_path_type(screenshot_path, :absolute)
      assert_in_directory(screenshot_path, screenshots_path)
      assert_file_exists(screenshot_path)
    end

    test "logs file url when the sets the screenshot_dir to a path in home dir", %{page: page} do
      screenshots_path =
        TestWorkspace.generate_temporary_path("~/.test wallaby screenshots-%{random_string}")

      ensure_setting_is_reset(:wallaby, :screenshot_dir)
      Application.put_env(:wallaby, :screenshot_dir, screenshots_path)

      output = capture_io(fn -> take_screenshot(page, log: true) end)

      assert [screenshot_path] =
               output
               |> extract_screenshot_urls()
               |> Enum.map(&path_from_file_url!/1)

      assert_path_type(screenshot_path, :absolute)
      assert_in_directory(screenshot_path, screenshots_path)
      assert_file_exists(screenshot_path)
    end
  end

  test "filters out illegal characters in screenshot name", %{page: page} do
    ensure_setting_is_reset(:wallaby, :screenshot_dir)
    Application.put_env(:wallaby, :screenshot_dir, "shots")

    [screenshot_path] =
      page
      |> take_screenshot(name: "some_page<>:\"/\\?*")
      |> Map.get(:screenshots)

    assert screenshot_path == "shots/some_page.png"

    File.rm_rf!("#{File.cwd!()}/shots")
  end

  defp assert_path_type(path, expected_path_type)
       when expected_path_type in [:relative, :absolute] do
    path_type = Path.type(path)

    assert path_type == expected_path_type, """
    Expected path_type to be #{inspect(expected_path_type)} but was #{inspect(path_type)}

    path: #{inspect(path)}
    """
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

  defp extract_screenshot_urls(output) do
    ~r/Screenshot taken, find it at (?<screenshot_url>\S+)/m
    |> Regex.scan(output, capture: :all_but_first)
    |> List.flatten()
  end

  defp path_from_file_url!(file_url) do
    case URI.parse(file_url) do
      # There is a difference between elixir 1.9 and 1.10 when checking
      # if a URI has no host: https://github.com/elixir-lang/elixir/issues/9837
      %URI{scheme: "file", host: host, path: path} when host in [nil, ""] and is_binary(path) ->
        URI.decode(path)

      parsed_uri ->
        flunk("""
        Invalid file url

          url: #{inspect(file_url)}

          Parsed into

          #{inspect(parsed_uri, pretty: true)}
        """)
    end
  end
end
