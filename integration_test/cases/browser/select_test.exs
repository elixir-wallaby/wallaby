defmodule Wallaby.Integration.Browser.SelectTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page =
      session
      |> visit("select_boxes.html")

    {:ok, page: page}
  end

  test "choosing an option from a select box by id", %{page: page} do
    refute find(page, "#select-option-2") |> selected?

    page
    |> select("select-box", option: "Option 2")

    assert find(page, "#select-option-2") |> selected?
  end

  test "choosing an option from a select box by name", %{page: page} do
    refute find(page, "#select-option-5") |> selected?

    page
    |> select("my-select", option: "Option 2")

    assert find(page, "#select-option-5") |> selected?
  end

  test "choosing an option from a select box by label", %{page: page} do
    refute find(page, "#select-option-5") |> selected?

    page
    |> select("My Select", option: "Option 2")

    assert find(page, "#select-option-5") |> selected?
  end

  test "choosing an option from a select box by label when for is id", %{page: page} do
    refute find(page, "#select-option-2") |> selected?

    page
    |> select("Select With ID", option: "Option 2")

    assert find(page, "#select-option-2") |> selected?
  end

  test "throw an error if a label exists but does not have a for attribute", %{page: page} do
    assert_raise Wallaby.QueryError, fn ->
      select(page, "Select with bad label", option: "Option")
    end
  end

  test "waits until the select appears", %{session: session} do
    page =
      session
      |> visit("forms.html")

    assert select(page, "Hidden Select", option: "Option")
  end

  test "escapes quotes", %{page: page} do
    assert select(page, "I'm a select", option: "I'm an option")
  end

  describe "select/2" do
    test "works with option queries", %{page: page} do
      assert page
      |> find(Query.select("My Select"))
      |> select(Query.option("Option 2"))
    end
  end

  describe "selected?/2" do
    test "returns a boolean if the option is selected", %{page: page} do
      assert page
      |> find(Query.select("My Select"))
      |> select(Query.option("Option 2"))
      |> selected?(Query.option("Option 2")) == true
    end
  end

  describe "selected?/1" do
    test "returns a boolean if the option is selected", %{page: page} do
      assert page
      |> find(Query.select("My Select"))
      |> select(Query.option("Option 2"))
      |> find(Query.option("Option 2"))
      |> selected? == true
    end
  end
end
