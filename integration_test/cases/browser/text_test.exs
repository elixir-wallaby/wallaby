defmodule Wallaby.Integration.Browser.TextTest do
  use Wallaby.Integration.SessionCase, async: true

  test "can get text of an element", %{session: session} do
    text =
      session
      |> visit("/")
      |> find(Query.css("#header"))
      |> Element.text()

    assert text == "Test Index"
  end

  test "can get text of an element and its descendants", %{session: session} do
    text =
      session
      |> visit("/")
      |> find(Query.css("#parent"))
      |> Element.text()

    assert text == "The Parent\nThe Child"
  end

  test "can get the text of a query", %{session: session} do
    text =
      session
      |> visit("/")
      |> text(Query.css("#parent"))

    assert text == "The Parent\nThe Child"
  end

  test "can get text of a session", %{session: session} do
    text =
      session
      |> visit("/")
      |> text()

    assert text == "Test Index\nPage 1\nPage 2\nPage 3\nThe Parent\nThe Child"
  end
end
