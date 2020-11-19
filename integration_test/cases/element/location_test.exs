defmodule Wallaby.Integration.Element.LocationTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "location/1" do
    test "returns coordinates of the top-left corner of the given element", %{page: page} do
      element = find(page, Query.text("Touch me!"))

      assert Element.location(element) == {0, 16}
    end
  end
end
