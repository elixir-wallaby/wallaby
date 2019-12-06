defmodule Wallaby.Integration.Browser.VisibleTest do
  use Wallaby.Integration.SessionCase, async: true

  describe "visible?/1" do
    setup :visit_page

    test "determines if the element is visible to the user", %{page: page} do
      page
      |> find(Query.css("#visible"))
      |> Element.visible?()
      |> assert

      page
      |> find(Query.css("#invisible", visible: false))
      |> Element.visible?()
      |> refute
    end

    test "handles elements that are not on the page", %{page: page} do
      element = find(page, Query.css("#off-the-page", visible: false))

      assert Element.visible?(element) == false
    end
  end

  describe "visible?/2" do
    setup :visit_page

    test "returns a boolean", %{page: page} do
      assert page
             |> visible?(Query.css("#visible")) == true

      assert page
             |> visible?(Query.css("#invisible")) == false
    end
  end

  def visit_page(%{session: session}) do
    page =
      session
      |> visit("page_1.html")

    {:ok, page: page}
  end
end
