defmodule Wallaby.Integration.Browser.TouchMoveTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_move/3" do
    test "moves touch pointer to the given point", %{page: page} do
      assert visible?(page, Query.text("Start", count: 0))
      assert visible?(page, Query.text("Move", count: 0))
      assert visible?(page, Query.text("End", count: 0))

      page
      |> touch_down(Query.text("Touch me!"))
      |> touch_move(200, 250)

      assert visible?(page, Query.text("Start 0 16"))
      assert visible?(page, Query.text("Move 200 250"))
      assert visible?(page, Query.text("End", count: 0))
    end
  end
end
