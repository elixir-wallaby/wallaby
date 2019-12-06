defmodule Wallaby.Integration.Browser.HasValueTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "forms.html")

    {:ok, %{page: page}}
  end

  @name_field Query.text_field("Name")

  describe "has_value?/3" do
    test "checks to see if query has a specific value", %{page: page} do
      assert page
             |> fill_in(@name_field, with: "Chris")
             |> has_value?(@name_field, "Chris")
    end
  end

  describe "has_value?/2" do
    test "checks that the elements value matches the specified value", %{page: page} do
      assert page
             |> fill_in(@name_field, with: "Chris")
             |> find(@name_field)
             |> has_value?("Chris")
    end
  end
end
