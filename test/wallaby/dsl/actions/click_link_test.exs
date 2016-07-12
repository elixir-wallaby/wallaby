defmodule Wallaby.DSL.Actions.ClickLinkTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "links.html")

    {:ok, page: page}
  end

  test "clicking link via link text redirects", %{page: page} do
    current_url =
      page
      |> click_link("Index")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking link via id redirects", %{page: page} do
    current_url =
      page
      |> click_link("id_link")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking Phoenix Method Link via text redirects", %{page: page} do
    current_url =
      page
      |> click_link("Phoenix Method Link")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking Phoenix Method Link via text doesn't redirect two times", %{page: page} do
    current_url =
      page
      |> click_link("Same Page")
      |> get_current_url

    refute current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end
end
