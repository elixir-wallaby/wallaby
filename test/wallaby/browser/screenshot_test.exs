defmodule Wallaby.Browser.ScreenshotTest do
  use Wallaby.SessionCase, async: false

  import Wallaby.Query, only: [css: 1]

  setup %{session: session} do
    page =
      session
      |> visit("/")

    {:ok, page: page}
  end

  test "taking screenshots", %{page: page} do
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

    Enum.each(element_screenshots ++ parent_screenshots, fn(path) ->
      assert File.exists? path
    end)

    File.rm_rf! "#{File.cwd!}/screenshots"
  end

  test "users can specify the screenshot directory", %{page: page} do
    Application.put_env(:wallaby, :screenshot_dir, "shots")

    screenshots =
      page
      |> take_screenshot
      |> Map.get(:screenshots)

    assert screenshots |> Enum.count == 1

    Enum.each screenshots, fn(path) ->
      assert path =~ ~r/^shots\/(.*)$/
      assert File.exists? path
    end

    Application.put_env(:wallaby, :screenshot_dir, nil)
    File.rm_rf! "#{File.cwd!}/shots"
  end

  test "automatically taking screenshots on failure", %{page: page} do
    assert_raise Wallaby.QueryError, fn ->
      find(page, ".some-selector")
    end
    refute File.exists?("#{File.cwd!}/screenshots")

    Application.put_env(:wallaby, :screenshot_on_failure, true)

    assert_raise Wallaby.QueryError, fn ->
      find(page, ".some-selector")
    end
    assert File.exists?("#{File.cwd!}/screenshots")
    assert File.ls!("#{File.cwd!}/screenshots") |> Enum.count == 1

    refute has?(page, css(".some-selector-that-does-not-exist"))
    assert File.ls!("#{File.cwd!}/screenshots") |> Enum.count == 2

    File.rm_rf! "#{File.cwd!}/screenshots"
    Application.put_env(:wallaby, :screenshot_on_failure, nil)
  end
end
