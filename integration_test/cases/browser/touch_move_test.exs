defmodule Wallaby.Integration.Browser.TouchMoveTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_move/3" do
    test "moves touch pointer to the given point", %{page: page} do
      refute visible?(page, Query.text("Start"))
      refute visible?(page, Query.text("Move"))
      refute visible?(page, Query.text("End"))

      page
      |> touch_down(Query.text("Touch me!"))
      |> touch_move(200, 250)

      assert visible?(page, Query.text("Start 100 100"))
      assert visible?(page, Query.text("Move 200 250"))
      refute visible?(page, Query.text("End"))
    end
  end
end