defmodule Wallaby.Browser.AttrTest do
  use Wallaby.SessionCase, async: true

  test "can get attributes of an element", %{session: session} do
    class =
      session
      |> visit("/")
      |> find("body")
      |> attr("class")

    assert class == "bootstrap"
  end

  test "can get the attributes of a query", %{session: session} do
    class =
      session
      |> visit("/")
      |> attr(Query.css("body"), "class")

    assert class == "bootstrap"
  end
end
