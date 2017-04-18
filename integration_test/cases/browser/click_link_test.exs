defmodule Wallaby.Integration.Browser.ClickLinkTest do
  use Wallaby.Integration.SessionCase, async: true

  test "click through to another page", %{session: session} do
    session
    |> visit("")
    |> click_link("Page 1")

    element =
      session
      |> find(Query.css(".blue"))

    assert element
  end

  describe "click_link/2" do
    setup %{session: session} do
      page = visit(session, "")

      {:ok, %{page: page}}
    end

    test "works with queries", %{page: page} do
      assert page
      |> click_link(Query.link("Page 1"))
    end
  end
end
