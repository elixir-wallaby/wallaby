defmodule Wallaby.Integration.Browser.TouchDownTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_down/2" do
    test "touches and holds given element", %{page: page} do
      refute visible?(page, Query.text("Start"))

      assert page
             |> touch_down(Query.text("Touch me!"))
             |> visible?(Query.text("Start 100 100"))

      assert page |> find(Query.css("#log-count-touches")) |> Element.text() == "1"

      refute visible?(page, Query.text("End"))
    end
  end
end
