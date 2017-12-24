defmodule Wallaby.Integration.Browser.RefuteTextTest do
  use Wallaby.Integration.SessionCase, async: true

  alias Wallaby.ExpectationNotMetError

  test "refute_text/2 waits for presence of text and returns true if not found", %{session: session} do
    element = session
              |> visit("wait.html")
              |> find(Query.css("#container"))

    assert refute_text(element, "not-present")
  end

  test "refute_text/2 will raise an exception when the text is found", %{session: session} do
    element = session
              |> visit("wait.html")
              |> find(Query.css("#container"))

    assert_raise ExpectationNotMetError, "Text 'main' was found.", fn ->
      refute_text(element, "main")
    end
  end

  test "refute_text/2 works with sessions", %{session: session} do
    session
    |> Browser.visit("wait.html")

    assert Browser.refute_text(session, "not-present")
  end
end
