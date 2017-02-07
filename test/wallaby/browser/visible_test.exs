defmodule Wallaby.Browser.VisibleTest do
  use Wallaby.SessionCase, async: true

  describe "visible?/1" do
    setup :visit_page

    test "determines if the element is visible to the user", %{page: page} do
      page
      |> find("#visible")
      |> visible?
      |> assert

      page
      |> find("#invisible", visible: false)
      |> visible?
      |> refute
    end

    test "handles elements that are not on the page", %{page: page} do
      element = find(page, "#off-the-page", visible: false)

      assert visible?(element) == false
    end

    @tag skip: "Unsuported in phantom"
    test "handles obscured elements", %{page: page} do
      element = find(page, "#obscured", visible: false)

      assert visible?(element) == false
    end
  end

  def visit_page(%{session: session}) do
    page =
      session
      |> visit("page_1.html")

    {:ok, page: page}
  end
end
