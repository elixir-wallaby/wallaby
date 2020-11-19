defmodule Wallaby.Integration.Element.TapTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "tap/1" do
    test "taps the given element", %{page: page} do
      element = find(page, Query.text("Touch me!"))

      assert visible?(page, Query.text("Start", count: 0))
      assert visible?(page, Query.text("End", count: 0))

      Element.tap(element)

      assert visible?(page, Query.text("Start"))
      assert visible?(page, Query.text("End"))
    end
  end
end
