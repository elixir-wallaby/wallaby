defmodule Wallaby.Browser.ChooseTest do
  use Wallaby.SessionCase, async: true
  alias Wallaby.Query, as: Q

  setup %{session: session} do
    page =
      session
      |> visit("forms.html")

    {:ok, page: page}
  end

  test "choosing a radio button", %{page: page} do
    refute find(page, "#option2") |> checked?

    page
    |> choose("option2")

    assert find(page, "#option2") |> checked?
  end

  test "choosing a radio button unchecks other buttons in the group", %{page: page} do
    page
    |> choose("Option 1")
    |> find(Query.css("#option1"))
    |> checked?
    |> assert

    page
    |> choose("option2")

    refute find(page, "#option1") |> checked?
    assert find(page, "#option2") |> checked?
  end

  test "choosing a radio button returns the parent", %{page: page} do
    page
    |> choose("Option 1")
    |> choose("option2")

    assert find(page, "#option2") |> checked?
  end

  test "throw an error if a label exists but does not have a for attribute", %{page: page} do
    bad_form =
      page
      |> find(Query.css(".bad-form"))

    assert_raise Wallaby.QueryError, fn ->
      choose(bad_form, "Radio with bad label")
    end
  end

  test "waits until the radio button appears", %{page: page} do
    assert choose(page, "Hidden Radio Button")
  end

  test "escape quotes", %{page: page} do
    assert choose(page, "I'm a radio button")
  end

  describe "choose/2" do
    test "works with radio_button queries", %{page: page} do
      assert page
      |> choose( Q.radio_button("Option 1") )
    end

    test "works with option queries", %{page: page} do
      assert page
      |> choose( Q.option("Select Option 1") )
    end

    test "works with other queries", %{page: page} do
      assert page
      |> choose( Q.css("#select-option-1") )
    end
  end
end
