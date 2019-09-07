defmodule Wallaby.Integration.Element.TouchDownTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_down/1" do
    test "touches and holds given element", %{page: page} do
      element = find(page, Query.text("Touch me!"))

      refute visible?(page, Query.text("Start"))

      Element.touch_down(element)

      assert visible?(page, Query.text("Start 100 100"))
      refute visible?(page, Query.text("End"))
      assert page |> find(Query.css("#log-count-touches")) |> Element.text() == "1"
    end
  end
end
