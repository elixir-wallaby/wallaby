defmodule Wallaby.Integration.Element.TapTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "tap/1" do
    test "taps the given element", %{page: page} do
      element = find(page, Query.text("Touch me!"))

      refute visible?(page, Query.text("Start"))
      refute visible?(page, Query.text("End"))

      Element.tap(element)

      assert visible?(page, Query.text("Start"))
      assert visible?(page, Query.text("End"))
    end
  end
end