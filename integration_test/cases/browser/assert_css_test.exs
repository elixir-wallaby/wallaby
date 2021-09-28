defmodule Wallaby.Integration.Browser.AssertCssTest do
  use Wallaby.Integration.SessionCase, async: true

  test "has_css/2 returns true if the css is on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    assert has_css?(page, ".user")
  end

  test "has_css/2 returns false if the css is not on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    refute has_css?(page, ".something_else")
  end

  test "has_css/3 returns true if the css is on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    assert has_css?(page, Query.css(".dashboard"), ".users")
  end

  test "has_css/3 returns false if the css is not on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    refute has_css?(page, Query.css(".dashboard"), ".something_else")
  end

  test "has_no_css/2 returns true if the css is not on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    assert has_no_css?(page, ".something_else")
  end

  test "has_no_css/2 returns false if the css is on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    refute has_no_css?(page, ".user")
  end

  test "has_no_css/3 returns false if the css is on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    refute has_no_css?(page, Query.css(".dashboard"), ".user")
  end

  test "has_no_css/3 returns true if the css is not on the page", %{session: session} do
    page =
      session
      |> visit("nesting.html")

    assert has_no_css?(page, Query.css(".dashboard"), ".something_else")
  end
end
