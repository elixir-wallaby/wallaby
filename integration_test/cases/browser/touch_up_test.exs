defmodule Wallaby.Integration.Browser.TouchUpTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "touch_up/1" do
    test "stops touching screen over the given element", %{page: page} do
      refute visible?(page, Query.text("Start"))

      assert page
             |> touch_down(Query.text("Touch me!"))
             |> visible?(Query.text("Start"))

      refute visible?(page, Query.text("End"))

      assert page
             |> touch_up()
             |> visible?(Query.text("End"))
    end
  end
end