defmodule Wallaby.Browser.AssertCssTest do
  use Wallaby.SessionCase, async: true

  test "has_css/2 returns true if the css is on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    assert has_css?(page, ".user")
  end

  test "has_no_css/2 checks is the css is not on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    assert has_no_css?(page, ".something_else")
  end

  test "has_no_css/2 raises error if the css is found", %{session: session} do
    refute session
    |> visit("nesting.html")
    |> has_no_css?(".user")
  end
end
