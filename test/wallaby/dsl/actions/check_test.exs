defmodule Wallaby.DSL.Actions.CheckTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "forms.html")

    {:ok, page: page}
  end

  test "check/1 checks the specified node", %{page: page} do
    checkbox =
      page
      |> find("#checkbox1")

    check checkbox
    assert checked?(checkbox)
    uncheck checkbox
    refute checked?(checkbox)
  end

  test "check/2 does not uncheck the node if called twice", %{page: page} do
    page
    |> check("Checkbox 1")
    |> check("Checkbox 1")

    assert find(page, "#checkbox1") |> checked?
  end

  test "uncheck/2 does not check the node", %{page: page} do
    page
    |> uncheck("Checkbox 1")

    refute find(page, "#checkbox1") |> checked?
  end

  test "check/2 finds the node by label", %{page: page} do
    page
    |> check("Checkbox 1")

    assert find(page, "#checkbox1") |> checked?
    uncheck(page, "Checkbox 1")
    refute find(page, "#checkbox1") |> checked?
  end

  test "check/2 finds the node by id", %{page: page} do
    page
    |> check("checkbox1")

    assert find(page, "#checkbox1") |> checked?
    uncheck(page, "checkbox1")
    refute find(page, "#checkbox1") |> checked?
  end

  test "check/2 finds the node by name", %{page: page} do
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
end
