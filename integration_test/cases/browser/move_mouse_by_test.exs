defmodule Wallaby.Integration.Browser.MoveMouseByTest do
  use Wallaby.Integration.SessionCase, async: true
  import Wallaby.Browser

  setup %{session: session} do
    {:ok, page: visit(session, "move_mouse.html")}
  end

  describe "move_mouse_by/3" do
    test "moves mouse cursor by the given offset from the current position", %{page: page} do
      refute page
             |> visible?(Query.text("B"))

      assert page
             |> hover(Query.text("A"))
             |> move_mouse_by(40, 68)
             |> visible?(Query.text("B"))
    end
  end
end
