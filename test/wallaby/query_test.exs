defmodule Wallaby.QueryTest do
  use ExUnit.Case, async: true

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
end
