defmodule Wallaby.Integration.Browser.TapTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "tap/2" do
    test "taps the given element", %{page: page} do
      assert visible?(page, Query.text("Start", count: 0))
      assert visible?(page, Query.text("End", count: 0))

      tap(page, Query.text("Touch me!"))

      assert visible?(page, Query.text("Start"))
      assert visible?(page, Query.text("End"))
      assert page |> find(Query.css("#log-count-touches")) |> Element.text() == "0"
    end
  end
end
