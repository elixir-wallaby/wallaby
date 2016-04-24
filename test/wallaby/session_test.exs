defmodule Wallaby.SessionTest do
  use Wallaby.ServerCase, async: false
  use Wallaby.DSL

  setup do
    {:ok, session} = Wallaby.start_session

    on_exit fn ->
      Wallaby.end_session(session)
    end

    {:ok, %{session: session}}
  end

  test "click through to another page", %{server: server, session: session} do
    session
    |> visit(server.base_url)
    |> click_link("Page 1")

    element =
      session
      |> find(".blue")

    assert element
  end

  test "navigating by path only", %{session: session, server: server} do
    Application.put_env(:wallaby, :base_url, server.base_url)
    session
    |> visit("page_1.html")

    element =
      session
      |> find(".blue")

    assert element
    Application.put_env(:wallaby, :base_url, nil)
  end

  test "visit/2 with a relative url and no base url raises exception", %{session: session, server: server} do
    assert_raise(Wallaby.NoBaseUrl, fn ->
      Application.put_env(:wallaby, :base_url, nil)
      session
      |> visit("/page_1.html")
    end)
  end

  test "visit/2 with an absolute path does not use the base url", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "/page_1.html")

    assert has_css?(session, "#visible")
  end

  test "taking screenshots", %{session: session, server: server} do
    node =
      session
      |> visit(server.base_url)
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

  test "manipulating window size", %{session: session, server: server} do
    window_size =
      session
      |> visit(server.base_url)
      |> set_window_size(1234, 1234)
      |> get_window_size

    assert window_size == %{"height" => 1234, "width" => 1234}
  end
end
