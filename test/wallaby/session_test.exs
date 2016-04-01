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

  test "taking a screenshot", %{session: session, server: server} do
    %{path: path} =
      session
      |> visit(server.base_url)
      |> take_screenshot

    assert File.exists? path
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
