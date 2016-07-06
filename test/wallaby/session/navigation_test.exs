defmodule Wallaby.Session.NavigationTest do
  use Wallaby.SessionCase, async: false

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

  test "visit/2 with a relative url and no base url raises exception", %{session: session} do
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
end
