defmodule Wallaby.Integration.Browser.HoverTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    {:ok, page: visit(session, "move_mouse.html")}
  end

  describe "hover/2" do
    test "hovers over the specified element", %{page: page} do
      refute page
             |> visible?(Query.text("B"))

      assert page
             |> hover(Query.css(".group"))
             |> visible?(Query.text("B"))
    end
  end
end
