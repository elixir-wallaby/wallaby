defmodule Wallaby.Integration.Browser.SelectTest do
  use Wallaby.Integration.SessionCase, async: true

  import Wallaby.Query, only: [option: 1, select: 1]

  setup %{session: session} do
    page =
      session
      |> visit("select_boxes.html")

    {:ok, page: page}
  end

  test "escapes quotes", %{page: page} do
    assert click(page, option("I'm an option"))
  end

  describe "selected?/2" do
    test "returns a boolean if the option is selected", %{page: page} do
      select =
        page
        |> find(select("My Select"))

      assert select
             |> selected?(option("Option 2")) == false

      assert select
             |> click(option("Option 2"))
             |> selected?(option("Option 2")) == true
    end
  end

  describe "selected?/1" do
    test "returns a boolean if the option is selected", %{page: page} do
      page
      |> find(select("My Select"))
      |> find(option("Option 2"), &refute(Element.selected?(&1)))
      |> click(option("Option 2"))
      |> find(option("Option 2"), &assert(Element.selected?(&1)))
    end
  end
end
