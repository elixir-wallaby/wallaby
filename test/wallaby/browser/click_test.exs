defmodule Wallaby.Browser.ClickTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "forms.html")

    {:ok, %{page: page}}
  end

  describe "click/2" do
    test "accepts queries", %{page: page} do
      assert page
      |> click(Query.button("Submit button"))
    end

    test "can click invisible elements", %{page: page} do
      assert page
      |> click(Query.button("Invisible Button", visible: false))
    end
  end
end
