defmodule Wallaby.Integration.Browser.AssertRefuteHasTest do
  use Wallaby.Integration.SessionCase, async: true

  alias Wallaby.ExpectationNotMetError

  @found_query Query.css(".user", count: :any)
  @not_found_query Query.css(".something-else")
  @wrong_exact_found_query Query.css(".user", count: 5)
  @at_query Query.css(".user", at: 3)
  @wrong_at_query Query.css(".user", at: 7)
  describe "assert_has/2" do
    test "passes if the query is present on the page", %{session: session} do
      return =
        session
        |> visit("nesting.html")
        |> assert_has(@found_query)

      assert %Wallaby.Session{} = return
    end

    test "raises if the query is not found", %{session: session} do
      assert_raise ExpectationNotMetError, ~r/Expected.+ 1.*css.*\.something-else.*0/i, fn ->
        session
        |> visit("nesting.html")
        |> assert_has(@not_found_query)
      end
    end

    test "mentions the count of found vs. expected elements", %{session: session} do
      assert_raise ExpectationNotMetError, ~r/Expected.+ 5.*css.*\.user.*6/i, fn ->
        session
        |> visit("nesting.html")
        |> assert_has(@wrong_exact_found_query)
      end
    end

    test "mentions the count of found vs. expected index", %{session: session} do
      expect =
        ~r/Expected.*and return element at index 7, but only 6 visible elements were found/i

      assert_raise ExpectationNotMetError, expect, fn ->
        session
        |> visit("nesting.html")
        |> assert_has(@wrong_at_query)
      end
    end

    test "passes if `at` element exists", %{session: session} do
      return =
        session
        |> visit("nesting.html")
        |> assert_has(@at_query)

      assert %Wallaby.Session{} = return
    end
  end

  describe "refute_has/2" do
    test "passes if the query is not found on the page", %{session: session} do
      return =
        session
        |> visit("nesting.html")
        |> refute_has(@not_found_query)

      assert %Wallaby.Session{} = return
    end

    test "raises if the query is found on the page", %{session: session} do
      assert_raise ExpectationNotMetError, ~r/Expected not.+any.*css.*\.user.*6/i, fn ->
        session
        |> visit("nesting.html")
        |> refute_has(@found_query)
      end
    end
  end
end
