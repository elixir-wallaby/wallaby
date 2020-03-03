defmodule Wallaby.Integration.Browser.AssertTextTest do
  use Wallaby.Integration.SessionCase, async: true

  alias Wallaby.ExpectationNotMetError

  test "has_text?/2 waits for presence of text and returns a bool", %{session: session} do
    element =
      session
      |> visit("wait.html")
      |> find(Query.css("#container"))

    assert has_text?(element, "main")
    refute has_text?(element, "rain")
  end

  test "assert_text/2 waits for presence of text and and returns true if found", %{
    session: session
  } do
    element =
      session
      |> visit("wait.html")
      |> find(Query.css("#container"))

    assert assert_text(element, "main")
  end

  test "assert_text/2 will raise an exception for text not found", %{session: session} do
    element =
      session
      |> visit("wait.html")
      |> find(Query.css("#container"))

    assert_raise ExpectationNotMetError, "Text 'rain' was not found.", fn ->
      assert_text(element, "rain")
    end
  end

  test "assert_text/2 works with sessions", %{session: session} do
    session
    |> Browser.visit("wait.html")

    assert Browser.assert_text(session, "main")
  end
end
