defmodule Wallaby.Integration.Element.HoverTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    {:ok, page: visit(session, "hover.html")}
  end

  describe "hover/2" do
    test "sends keys to the specified element", %{page: page} do
      page
      |> find(Query.text("HI", visible: false), fn el ->
        refute Element.visible?(el)
      end)
      |> find(Query.css(".group"), fn el ->
        Element.hover(el)
      end)
      |> find(Query.text("HI"), fn el ->
        assert Element.visible?(el)
      end)
    end
  end
end
