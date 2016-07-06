defmodule Wallaby.Session.ScreenshotTest do
  use Wallaby.SessionCase, async: false

  setup %{server: server, session: session} do
    page =
      session
      |> visit(server.base_url)

    {:ok, page: page}
  end

  test "taking screenshots", %{page: page} do
    node =
      page
      |> take_screenshot
      |> find("#header")
      |> take_screenshot

    screenshots =
      node
      |> Map.get(:session)
      |> Map.get(:screenshots)

    assert Enum.count(screenshots) == 2

    Enum.each(screenshots, fn(path) ->
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
    assert_raise Wallaby.ElementNotFound, fn ->
      find(page, ".some-selector")
    end
    refute File.exists?("#{File.cwd!}/screenshots")

    Application.put_env(:wallaby, :screenshot_on_failure, true)

    assert_raise Wallaby.ElementNotFound, fn ->
      find(page, ".some-selector")
    end
    assert File.exists?("#{File.cwd!}/screenshots")
    assert File.ls!("#{File.cwd!}/screenshots") |> Enum.count == 1

    File.rm_rf! "#{File.cwd!}/screenshots"
    Application.put_env(:wallaby, :screenshot_on_failure, nil)
  end
end
