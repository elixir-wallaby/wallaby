defmodule Wallaby.Integration.Browser.DoubleClickTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "click.html")

    {:ok, %{page: page}}
  end

  describe "double_click/1" do
    test "double-clicks left mouse button at the current cursor position", %{page: page} do
      refute page
             |> visible?(Query.text("Double"))

      assert page
             |> hover(Query.text("Click"))
             |> double_click()
             |> visible?(Query.text("Double"))
    end
  end
end
