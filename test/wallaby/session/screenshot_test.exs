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

    parent_screenshots =
      node
      |> Map.get(:parent)
      |> Map.get(:screenshots)

    node_screenshots =
      node
      |> Map.get(:screenshots)

    assert Enum.count(node_screenshots) == 1
    assert Enum.count(parent_screenshots) == 1

    Enum.each(node_screenshots ++ parent_screenshots, fn(path) ->
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

    File.rm_rf! "#{File.cwd!}/screenshots"
    Application.put_env(:wallaby, :screenshot_on_failure, nil)
  end
end
