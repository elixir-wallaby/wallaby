defmodule Wallaby.Integration.Element.SizeTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "touch.html")

    {:ok, %{page: page}}
  end

  describe "size/1" do
    test "returns size of the given element", %{page: page} do
      element = find(page, Query.text("Touch me!"))

      assert Element.size(element) == {200, 100}
    end
  end
end
