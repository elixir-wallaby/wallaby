defmodule Wallaby.Integration.Browser.TouchScrollTest do
  use Wallaby.Integration.SessionCase, async: true
  alias Wallaby.Integration.Helpers

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_scroll/4" do
    test "scrolls the page using touch events", %{page: page} do
      refute visible?(page, Query.text("Start"))
      refute visible?(page, Query.text("Move"))
      refute visible?(page, Query.text("End"))
      refute Helpers.displayed_in_viewport?(page, Query.text("Hello there"))

      touch_scroll(page, Query.text("Touch me!"), 1000, 1000)

      assert Helpers.displayed_in_viewport?(page, Query.text("Hello there"))

      assert visible?(page, Query.text("Start 100 100"))
      assert visible?(page, Query.text("Move"))
      assert visible?(page, Query.text("End"))
    end
  end
end
