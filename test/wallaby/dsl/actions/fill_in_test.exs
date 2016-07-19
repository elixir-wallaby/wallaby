defmodule Wallaby.Actions.FillInTest do
  use Wallaby.SessionCase, async: true

  setup %{server: server, session: session} do
    page =
      session
      |> visit(server.base_url <> "forms.html")

    {:ok, %{page: page}}
  end

  test "filling in input by name", %{page: page} do
    page
    |> fill_in("name", with: "Chris")

    assert find(page, "#name_field") |> has_value?("Chris")
  end

  test "filling in input by id", %{page: page} do
    page
    |> fill_in("name_field", with: "Chris")

    assert find(page, "#name_field") |> has_value?("Chris")
  end

  test "fill_in accepts numbers", %{page: page} do
    page
    |> fill_in("password", with: 1234)

    assert find(page, "#password_field") |> has_value?("1234")
  end

  test "filling in multiple inputs", %{page: page} do
    page
    |> fill_in("name", with: "Alex")
    |> fill_in("email", with: "alex@example.com")

    assert find(page, "#name_field")  |> has_value?("Alex")
    assert find(page, "#email_field") |> has_value?("alex@example.com")
  end

  test "fill_in replaces all of the text", %{page: page} do
    page
    |> fill_in("name", with: "Chris")
    |> fill_in("name", with: "Alex")

    assert find(page, "#name_field") |> has_value?("Alex")
  end

  test "throw an error if a label exists but does not have a for attribute", %{page: page} do
    bad_form =
      page
      |> find(".bad-form")

    assert_raise Wallaby.BadHTML, fn ->
      fill_in(bad_form, "Input with bad label", with: "Test Value")
    end
  end

  test "waits until the input appears", %{page: page} do
    assert fill_in(page, "Hidden Text Field", with: "Test Label Text")
  end
end
