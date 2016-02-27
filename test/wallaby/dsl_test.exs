defmodule Wallaby.DSLTest do
  use ExUnit.Case

  use Wallaby.DSL

  test "can find an element on a page" do
    element =
      session
      |> visit("/test_page.html")
      |> find("#header")

    assert element
  end
end
