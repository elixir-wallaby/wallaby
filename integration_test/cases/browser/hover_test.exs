defmodule Wallaby.Integration.Browser.HoverTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    {:ok, page: visit(session, "hover.html")}
  end

  describe "hover/2" do
    test "hovers over the specified element", %{page: page} do
      refute page
             |> visible?(Query.text("HI"))

      assert page
             |> hover(Query.css(".group"))
             |> visible?(Query.text("HI"))
    end
  end
end
