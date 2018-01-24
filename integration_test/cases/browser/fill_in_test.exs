defmodule Wallaby.Integration.Browser.FillInTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page =
      session
      |> visit("forms.html")

    {:ok, %{page: page}}
  end

  test "fill_in/2 accepts a query", %{page: page} do
    page
    |> fill_in(Query.text_field("name"), with: "Chris")

    assert page
    |> find(Query.text_field("name"))
    |> has_value?("Chris")
  end

  test "filling in input by id", %{page: page} do
    page
    |> fill_in(Query.css("#name_field"), with: "Chris")

    assert find(page, Query.css("#name_field")) |> has_value?("Chris")
  end

  test "fill_in accepts numbers", %{page: page} do
    page
    |> fill_in(Query.text_field("password"), with: 1234)

    assert find(page, Query.css("#password_field")) |> has_value?("1234")
  end

  test "filling in multiple inputs", %{page: page} do
    page
    |> fill_in(Query.text_field("name"), with: "Alex")
    |> fill_in(Query.text_field("email"), with: "alex@example.com")

    assert page
           |> find(Query.css("#name_field"))
           |> has_value?("Alex")
    assert page
           |> find(Query.css("#email_field"))
           |> has_value?("alex@example.com")
  end

  test "fill_in replaces all of the text", %{page: page} do
    page
    |> fill_in(Query.text_field("name"), with: "Chris")
    |> fill_in(Query.text_field("name"), with: "Alex")

    assert find(page, Query.css("#name_field")) |> has_value?("Alex")
  end

  test "waits until the input appears", %{page: page} do
    fill_in(page, Query.text_field("Hidden Text Field"), with: "Test Label Text")

    assert page
           |> find(Query.css("#hidden-text-field-id"))
           |> has_value?("Test Label Text")
  end

  test "checks for labels without for attributes", %{page: page} do
    assert_raise Wallaby.QueryError, ~r/label has no 'for'/, fn ->
      fill_in(page, Query.text_field("Input with bad label"), with: "Test")
    end
  end

  test "checks for mismatched ids on labels", %{page: page} do
    assert_raise Wallaby.QueryError, ~r/but the label's 'for' attribute/, fn ->
      fill_in(page, Query.text_field("Input with bad id"), with: "Test")
    end
  end

  test "escapes quotes", %{page: page} do
    assert fill_in(page, Query.text_field("I'm a text field"), with: "Stuff")
  end

  test "works with unicode", %{page: page} do
    page
    |> fill_in(Query.text_field("name"), with: "Chris 🎉")
    |> find(Query.text_field("name"), fn field ->
      field
      |> take_screenshot()
      assert has_value?(field, "Chris 🎉")
    end)
  end
end
