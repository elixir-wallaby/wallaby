defmodule Wallaby.Integration.Browser.ClickMouseButtonTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "click.html")

    {:ok, %{page: page}}
  end

  describe "click/2 for clicking at current mouse position" do
    test "clicks left button", %{page: page} do
      refute page
             |> visible?(Query.text("Left"))

      assert page
             |> hover(Query.text("Click"))
             |> click(:left)
             |> visible?(Query.text("Left"))
    end

    test "clicks middle button", %{page: page} do
      refute page
             |> visible?(Query.text("Middle"))

      assert page
             |> hover(Query.text("Click"))
             |> click(:middle)
             |> visible?(Query.text("Middle"))
    end

    test "clicks right button", %{page: page} do
      refute page
             |> visible?(Query.text("Right"))

      assert page
             |> hover(Query.text("Click"))
             |> click(:right)
             |> visible?(Query.text("Right"))
    end
  end
end
