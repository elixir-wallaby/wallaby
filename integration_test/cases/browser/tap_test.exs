defmodule Wallaby.Integration.Browser.TapTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "tap/2" do
    test "taps the given element", %{page: page} do
      refute visible?(page, Query.text("Start"))
      refute visible?(page, Query.text("End"))

      tap(page, Query.text("Touch me!"))

      assert visible?(page, Query.text("Start"))
      assert visible?(page, Query.text("End"))
    end
  end
end