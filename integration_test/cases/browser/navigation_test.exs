defmodule Wallaby.Integration.Browser.NavigationTest do
  use Wallaby.Integration.SessionCase, async: false

  test "navigating by path only", %{session: session} do
    visit(session, "page_1.html")

    element =
      session
      |> find(Query.css(".blue"))

    assert element
  end

  test "visit/2 with an absolute path does not use the base url", %{session: session} do
    session
    |> visit("/page_1.html")

    assert has_css?(session, "#visible")
  end
end
