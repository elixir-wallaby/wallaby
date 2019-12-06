defmodule Wallaby.Integration.Browser.ClearTest do
  use Wallaby.Integration.SessionCase, async: true

  test "clearing input", %{session: session} do
    element =
      session
      |> visit("forms.html")
      |> find(Query.css("#name_field"))

    Element.fill_in(element, with: "Chris")
    assert has_value?(element, "Chris")

    Element.clear(element)
    refute has_value?(element, "Chris")
    assert has_value?(element, "")
  end

  describe "clear/2" do
    setup %{session: session} do
      page = visit(session, "forms.html")
      {:ok, %{page: page}}
    end

    test "works with queries", %{page: page} do
      assert page
             |> fill_in(Query.text_field("name_field"), with: "test")
             |> clear(Query.text_field("name_field"))
             |> text(Query.text_field("name_field")) == ""
    end
  end
end
