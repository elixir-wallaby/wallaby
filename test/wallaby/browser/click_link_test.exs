defmodule Wallaby.Browser.ClickLinkTest do
  use Wallaby.SessionCase, async: true

  test "click through to another page", %{session: session} do
    session
    |> visit("")
    |> click_link("Page 1")

    element =
      session
      |> find(".blue")

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
