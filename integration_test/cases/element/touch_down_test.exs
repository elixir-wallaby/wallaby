defmodule Wallaby.Integration.Element.TouchDownTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_down/3" do
    test "touches and holds given element on its top-left corner", %{page: page} do
      element = find(page, Query.text("Touch me!"))

      refute visible?(page, Query.text("Start"))

      Element.touch_down(element)

      assert visible?(page, Query.text("Start 0 16"))
      refute visible?(page, Query.text("End"))
      assert page |> find(Query.css("#log-count-touches")) |> Element.text() == "1"
    end

    test "touches and holds given element on the point moved by given offset from its top-left corner", %{page: page} do
      element = find(page, Query.text("Touch me!"))

      refute visible?(page, Query.text("Start"))

      Element.touch_down(element, 10, 20)

      assert visible?(page, Query.text("Start 10 36"))
      refute visible?(page, Query.text("End"))
      assert page |> find(Query.css("#log-count-touches")) |> Element.text() == "1"
    end
  end
end
