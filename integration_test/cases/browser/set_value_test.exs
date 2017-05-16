defmodule Wallaby.Integration.Browser.SetValueTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "forms.html")
    {:ok, %{page: page}}
  end

  describe "set_value/3" do
    test "allows text field to be set", %{page: page} do
      assert page
             |> set_value(Query.text_field("email"), "Example text")
             |> find(Query.text_field("email"))
             |> has_value?("Example text")
    end

    test "allows checkbox to be checked", %{page: page} do
      assert page
             |> set_value(Query.checkbox("checkbox1"), :selected)
             |> find(Query.checkbox("checkbox1"))
             |> Element.selected?()
    end

    test "allows checkbox to be unchecked", %{page: page} do
      refute page
             |> set_value(Query.checkbox("checkbox1"), :selected)
             |> set_value(Query.checkbox("checkbox1"), :unselected)
             |> find(Query.checkbox("checkbox1"))
             |> Element.selected?()
    end

    test "allows radio buttons to be selected", %{page: page} do
      assert page
             |> set_value(Query.radio_button("option1"), :selected)
             |> find(Query.radio_button("option1"))
             |> Element.selected?()

      refute page
             |> set_value(Query.radio_button("option1"), :selected)
             |> set_value(Query.radio_button("option2"), :selected)
             |> find(Query.radio_button("option1"))
             |> Element.selected?()
    end

    test "allows options to be selected", %{page: page} do
      assert page
             |> set_value(Query.option("Select Option 1"), :selected)
             |> find(Query.option("Select Option 1"))
             |> Element.selected?()

      refute page
             |> set_value(Query.option("Select Option 1"), :selected)
             |> set_value(Query.option("Select Option 2"), :selected)
             |> find(Query.option("Select Option 1"))
             |> Element.selected?()
    end
  end
end
