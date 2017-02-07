defmodule Wallaby.Browser.AssertTextTest do
  use Wallaby.SessionCase, async: true

  test "has_text?/2 waits for presence of text and returns a bool", %{session: session} do
    element =
    session
      |> visit("wait.html")
      |> find("#container")

    assert has_text?(element, "main")
    refute has_text?(element, "rain")
  end

  test "assert_text/2 waits for presence of text and and returns true if found", %{session: session} do
    element =
    session
      |> visit("wait.html")
      |> find("#container")

    assert assert_text(element, "main")
  end

  test "assert_text/2 will raise an exception for text not found", %{session: session} do
    element =
    session
      |> visit("wait.html")
      |> find("#container")

    assert_raise Wallaby.ExpectationNotMet, "Text 'rain' was not found.", fn ->
      assert_text(element, "rain")
    end
  end
end
