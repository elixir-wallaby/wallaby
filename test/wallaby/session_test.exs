defmodule Wallaby.SessionTest do
  use Wallaby.SessionCase, async: true
  use Wallaby.DSL

  test "click through to another page", %{server: server, session: session} do
    session
    |> visit(server.base_url)
    |> click_link("Page 1")

    element =
      session
      |> find(".blue")

    assert element
  end

  test "gets the current_url of the session", %{server: server, session: session}  do
    current_url =
      session
      |> visit(server.base_url)
      |> click_link("Page 1")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/page_1.html"
  end

  test "gets the current_path of the session", %{server: server, session: session}  do
    current_path =
      session
      |> visit(server.base_url)
      |> click_link("Page 1")
      |> get_current_path

    assert current_path == "/page_1.html"
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
