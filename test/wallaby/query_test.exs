defmodule Wallaby.QueryTest do
  use ExUnit.Case, async: true
  doctest Wallaby.Query

  alias Wallaby.Query

  describe "default count" do
    test "the count defaults to 1 if no count is specified" do
      conditions = Query.css(nil).conditions
      assert conditions[:count] == 1

      conditions = Query.css(nil, count: 1).conditions
      assert conditions[:count] == 1

      conditions = Query.css(nil, count: 3).conditions
      assert conditions[:count] == 3
    end

    test "the count is nil if a minimum or maximum is set" do
      conditions = Query.css(nil, minimum: 1).conditions
      assert conditions[:count] == nil
      assert conditions[:minimum] == 1

      conditions = Query.css(nil, maximum: 1).conditions
      assert conditions[:count] == nil
      assert conditions[:maximum] == 1
    end
  end

  describe "matches_count?/1" do
    test "the results must match exactly if the count key is specified" do
      query = %Query{conditions: [count: 0]}
      assert Query.matches_count?(query, 0)

      query = %Query{conditions: [count: 1]}
      assert Query.matches_count?(query, 1)

      query = %Query{conditions: [count: 1]}
      refute Query.matches_count?(query, 0)

      query = %Query{conditions: [count: 1]}
      refute Query.matches_count?(query, 2)
    end

    test "the count key overrides other matching strategies" do
      query = %Query{conditions: [count: 1, minimum: 2], result: [%{}]}
      assert Query.matches_count?(query, 1)

      query = %Query{conditions: [count: 1, minimum: 4, maximum: 2], result: [%{}]}
      assert Query.matches_count?(query, 1)
    end

    test "the count must be above the minimum" do
      query = %Query{conditions: [minimum: 1], result: [%{}, %{}]}
      assert Query.matches_count?(query, 2)

      query = %Query{conditions: [minimum: 2], result: [%{}]}
      refute Query.matches_count?(query, 1)
    end

    test "the count must be below the maximum" do
      query = %Query{conditions: [maximum: 3], result: [%{}, %{}]}
      assert Query.matches_count?(query, 2)

      query = %Query{conditions: [maximum: 1], result: [%{}, %{}]}
      refute Query.matches_count?(query, 2)
    end

    test "the count must match minimum and maximum filters" do
      query = %Query{
        conditions: [minimum: 1, maximum: 3],
        result: [%{}, %{}]
      }
      assert Query.matches_count?(query, 2)

      query = %Query{conditions: [minimum: 1, maximum: 1], result: [%{}]}
      assert Query.matches_count?(query, 1)

      query = %Query{conditions: [minimum: 1, maximum: 1], result: [%{}, %{}]}
      refute Query.matches_count?(query, 2)
    end

    test "the result is greater then zero if count is any" do
      query = %Query{conditions: [count: :any], result: [%{}]}
      assert Query.matches_count?(query, 1)

      query = %Query{conditions: [count: :any], result: []}
      refute Query.matches_count?(query, 0)
    end
  end

  describe "validate/1" do
    test "when minimum is less then the maximum" do
      query = Query.css("#test", minimum: 5, maximum: 3)
      assert Query.validate(query) == {:error, :min_max}
    end
  end

  describe "visible/2" do
    test "marks query as visible when true is passed" do
      query =
        Query.css("#test", visible: false)
        |> Query.visible(true)

      assert Query.visible?(query)
    end

    test "marks query as hidden when false is passed" do
      query =
        Query.css("#test", visible: true)
        |> Query.visible(false)

      refute Query.visible?(query)
    end
  end

  describe "selected/2" do
    test "marks query as selected when true is passed" do
      query =
        Query.css("#test", selected: false)
        |> Query.selected(true)

      assert Query.selected?(query)
    end

    test "marks query as unselected when false is passed" do
      query =
        Query.css("#test", selected: true)
        |> Query.selected(false)

      refute Query.selected?(query)
    end
  end

  describe "text/2 when a query is passed" do
    test "sets the text option of the query" do
      query =
        Query.css("#test")
        |> Query.text("Submit")

      assert Query.inner_text(query) == "Submit"
    end
  end

  describe "text/2 when a selector is passed" do
    test "creates a text query" do
      query = Query.text("Submit")

      assert query.method == :text
    end

    test "accepts options" do
      query = Query.text("Submit", count: 1)

      assert query.method == :text
      assert Query.count(query) == 1
    end
  end

  describe "count/2" do
    test "sets the count in a query" do
      query =
        Query.css(".test")
        |> Query.count(9)

      assert Query.count(query) == 9
    end
  end

  describe "at/2" do
    test "sets at option in a query" do
      query =
        Query.css(".test")
        |> Query.at(3)

      assert Query.at_number(query) == 3
    end
  end
end
