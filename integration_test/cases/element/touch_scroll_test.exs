defmodule Wallaby.Integration.Element.TouchScrollTest do
  use Wallaby.Integration.SessionCase, async: true
  alias Wallaby.Integration.Helpers

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_scroll/3" do
    test "scrolls the page using touch events", %{page: page} do
      refute Helpers.displayed_in_viewport?(page, Query.text("Hello there"))

      element = find(page, Query.text("Touch me!"))
      Element.touch_scroll(element, 1000, 1000)

      assert Helpers.displayed_in_viewport?(page, Query.text("Hello there"))
      refute Helpers.displayed_in_viewport?(page, Query.text("Touch me!"))
    end
  end
end
