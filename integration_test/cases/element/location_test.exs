defmodule Wallaby.Integration.Element.LocationTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "location/1" do
    test "returns coordinates of the middle of the given element", %{page: page} do
      element = find(page, Query.text("Touch me!"))

      assert Element.location(element) == {100, 100}
    end
  end
end