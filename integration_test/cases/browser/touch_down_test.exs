defmodule Wallaby.Integration.Browser.TouchDownTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_down/4" do
    test "touches and holds given element on its top-left corner", %{page: page} do
      refute visible?(page, Query.text("Start"))

      assert page
             |> touch_down(Query.text("Touch me!"))
             |> visible?(Query.text("Start 0 16"))

      assert page |> find(Query.css("#log-count-touches")) |> Element.text() == "1"

      refute visible?(page, Query.text("End"))
    end

    test "touches and holds given element on the point moved by given offset from its top-left corner", %{page: page} do
      refute visible?(page, Query.text("Start"))

      assert page
             |> touch_down(Query.text("Touch me!"), 10, 20)
             |> visible?(Query.text("Start 10 36"))

      assert page |> find(Query.css("#log-count-touches")) |> Element.text() == "1"

      refute visible?(page, Query.text("End"))
    end
  end
end
