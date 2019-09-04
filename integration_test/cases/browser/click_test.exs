defmodule Wallaby.Integration.Browser.ClickTest do
  use Wallaby.Integration.SessionCase, async: true

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

    test "can be chained/returns parent", %{page: page} do
      page
      |> click(Query.css("#option1"))
      |> click(Query.css("#option2"))

      assert selected?(page, Query.css("#option2"))
    end
  end

  describe "click/2 with radio buttons (choose replacement)" do
    test "choosing a radio button", %{page: page} do
      refute selected?(page, Query.css("#option2"))

      page
      |> click(Query.radio_button("option2"))

      assert selected?(page, Query.css("#option2"))
    end

    test "choosing a radio button unchecks other buttons in the group", %{page: page} do
      page
      |> click(Query.radio_button("Option 1"))
      |> selected?(Query.css("#option1"))
      |> assert

      page
      |> click(Query.radio_button("option2"))

      refute selected?(page, Query.css("#option1"))
      assert selected?(page, Query.css("#option2"))
    end

    test "throw an error if a label exists but does not have a for attribute", %{page: page} do
      bad_form =
        page
        |> find(Query.css(".bad-form"))

      assert_raise Wallaby.QueryError, fn ->
        click(bad_form, Query.radio_button("Radio with bad label"))
      end
    end

    test "throw an error if the query matches multiple labels", %{page: page} do
      assert_raise Wallaby.QueryError, ~r/Expected (.*) 1/, fn ->
        click(page, Query.radio_button("Duplicate Radiobutton"))
      end
    end

    test "waits until the radio button appears", %{page: page} do
      assert click(page, Query.radio_button("Hidden Radio Button"))
    end

    test "escape quotes", %{page: page} do
      assert click(page, Query.radio_button("I'm a radio button"))
    end
  end

  describe "click/2 with checkboxes" do
    test "checking a checkbox", %{page: page} do
      assert page
             |> click(Query.checkbox("Checkbox 1"))
             |> click(Query.checkbox("Checkbox 1"))

      refute page
             |> find(Query.checkbox("Checkbox 1"))
             |> Element.selected?()
    end

    test "escapes quotes", %{page: page} do
      assert click(page, Query.checkbox("I'm a checkbox"))
    end

    test "throw an error if a label exists but does not have a for attribute", %{page: page} do
      assert_raise Wallaby.QueryError, fn ->
        click(page, Query.checkbox("Checkbox with bad label"))
      end
    end

    test "waits until the checkbox appears", %{page: page} do
      assert click(page, Query.checkbox("Hidden Checkbox"))
    end
  end

  describe "click/2 with links" do
    test "works with queries", %{page: page} do
      assert page
             |> visit("")
             |> click(Query.link("Page 1"))
             |> assert_has(Query.css(".blue"))
    end
  end

  describe "click/2 with buttons" do
    test "works with queries", %{page: page} do
      assert page
             |> click(Query.button("Reset input"))
    end
  end
end
