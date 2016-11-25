defmodule Wallaby.Browser.CheckTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session} do
    page =
      session
      |> visit("forms.html")

    {:ok, page: page}
  end

  test "check/1 checks the specified element", %{page: page} do
    checkbox =
      page
      |> find("#checkbox1")

    check checkbox
    assert checked?(checkbox)
    uncheck checkbox
    refute checked?(checkbox)
  end

  test "check/2 does not uncheck the element if called twice", %{page: page} do
    page
    |> check("Checkbox 1")
    |> check("Checkbox 1")

    assert find(page, "#checkbox1") |> checked?
  end

  test "uncheck/2 does not check the element", %{page: page} do
    page
    |> uncheck("Checkbox 1")

    refute find(page, "#checkbox1") |> checked?
  end

  test "check/2 finds the element by label", %{page: page} do
    page
    |> check("Checkbox 1")

    assert find(page, "#checkbox1") |> checked?
    uncheck(page, "Checkbox 1")
    refute find(page, "#checkbox1") |> checked?
  end

  test "check/2 finds the element by id", %{page: page} do
    page
    |> check("checkbox1")

    assert find(page, "#checkbox1") |> checked?
    uncheck(page, "checkbox1")
    refute find(page, "#checkbox1") |> checked?
  end

  test "check/2 finds the element by name", %{page: page} do
    page
    |> check("testbox")

    assert find(page, "#checkbox1") |> checked?
    uncheck(page, "testbox")
    refute find(page, "#checkbox1") |> checked?
  end

  test "throw an error if a label exists but does not have a for attribute", %{page: page} do
    assert_raise Wallaby.QueryError, fn ->
      check(page, "Checkbox with bad label")
    end
  end

  test "waits until the checkbox appears", %{page: page} do
    assert check(page, "Hidden Checkbox")
  end

  test "escapes quotes", %{page: page} do
    assert check(page, "I'm a checkbox")
  end

  describe "check/2" do
    test "works with checkbox queries", %{page: page} do
      assert page
      |> check( Query.checkbox("Checkbox 1") )
    end

    test "works with css queries", %{page: page} do
      assert page
      |> check( Query.css("#checkbox1") )
    end
  end

  describe "uncheck/2" do
    test "works with checkbox queries", %{page: page} do
      assert page
      |> check( Query.checkbox("Checkbox 1") )
      |> uncheck( Query.checkbox("Checkbox 1") )
    end

    test "works with css queries", %{page: page} do
      assert page
      |> check( Query.css("#checkbox1") )
      |> uncheck( Query.css("#checkbox1") )
    end
  end
end
