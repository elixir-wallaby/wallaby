defmodule Wallaby.Integration.Element.TouchScrollTest do
  use Wallaby.Integration.SessionCase, async: true
  alias Wallaby.Integration.Helpers

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_scroll/3" do
    test "scrolls the page using touch events", %{page: page} do
      assert visible?(page, Query.text("Start", count: 0))
      assert visible?(page, Query.text("Move", count: 0))
      assert visible?(page, Query.text("End", count: 0))
      refute Helpers.displayed_in_viewport?(page, Query.text("Hello there"))

      element = find(page, Query.text("Touch me!"))
      Element.touch_scroll(element, 1000, 1000)

      assert Helpers.displayed_in_viewport?(page, Query.text("Hello there"))

      assert visible?(page, Query.text("Start 100 66"))
      assert visible?(page, Query.text("Move"))
      assert visible?(page, Query.text("End"))
    end
  end
end
