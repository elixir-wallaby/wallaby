defmodule Wallaby.Browser.TextTest do
  use Wallaby.SessionCase, async: true

  test "can get text of an element", %{session: session} do
    text =
      session
      |> visit("/")
      |> find("#header")
      |> text()

    assert text == "Test Index"
  end

  test "can get text of an element and its descendants", %{session: session} do
    text =
      session
      |> visit("/")
      |> find("#parent")
      |> text()

    assert text == "The Parent\nThe Child"
  end

  test "can get the text of a query", %{session: session} do
    text =
      session
      |> visit("/")
      |> text(Query.css("#parent"))

    assert text == "The Parent\nThe Child"
  end
end
