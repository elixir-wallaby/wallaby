defmodule Wallaby.Browser.AssertCssTest do
  use Wallaby.SessionCase, async: true

  @found_query Query.css(".user", count: :any)
  @not_found_query Query.css(".something-else")
  describe "assert_has/2" do
    test "passes if the query is present on the page", %{session: session} do
      return = session
               |> visit("nesting.html")
               |> assert_has(@found_query)

      assert %Wallaby.Session{} = return
    end

    test "raises if the query is not found", %{session: session} do
      assert_raise Wallaby.ExpectationNotMet, ~r/css.*\.something-else/i, fn ->
        session
        |> visit("nesting.html")
        |> assert_has(@not_found_query)
      end
    end
  end

  describe "refute_has/2" do
    test "passes if the query is not found on the page", %{session: session} do
      return = session
               |> visit("nesting.html")
               |> refute_has(@not_found_query)

      assert %Wallaby.Session{} = return
    end

    test "raises if the query is found on the page", %{session: session} do
      assert_raise Wallaby.ExpectationNotMet, ~r/css.*\.user/i, fn ->
        session
        |> visit("nesting.html")
        |> refute_has(@found_query)
      end
    end
  end
end
