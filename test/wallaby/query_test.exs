defmodule Wallaby.QueryTest do
  use ExUnit.Case, async: true
  use Quixir

  alias Wallaby.Browser
  alias Wallaby.Query
  import Query

  test "the driver can execute queries" do
    {:ok, session} = Wallaby.start_session

    elements =
      session
      |> Browser.visit("/")
      |> Browser.find(Query.css("#child"))

    assert elements != "Failure"
  end

  test "disregards elements that don't match all filters" do
    {:ok, session} = Wallaby.start_session

    elements =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(css(".conflicting", count: 2, text: "Visible", visible: true))

    assert Enum.count(elements) == 2
  end

  describe "filtering queries by visibility" do
    test "finds elements that are invisible" do
      {:ok, session} = Wallaby.start_session

      assert_raise Wallaby.QueryError, fn ->
        session
        |> Browser.visit("/page_1.html")
        |> Browser.find(css(".invisible-elements", count: 3))
      end

      elements =
        session
        |> Browser.visit("/page_1.html")
        |> Browser.find(css(".invisible-elements", count: 3, visible: false))

      assert Enum.count(elements) == 3
    end

    test "doesn't error if the count is 'any' and some elements are visible" do
      {:ok, session} = Wallaby.start_session

      element =
        session
        |> Browser.visit("/page_1.html")
        |> Browser.find(css("#same-selectors-with-different-visibilities"))
        |> Browser.find(css("span", text: "Visible", count: :any))

      assert Enum.count(element) == 2
    end

    # TODO: Probs should totes remove this.
    @tag :pending
    test "informs the user that there are potential matches" do
      {:ok, session} = Wallaby.start_session

      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(css("#invisible"))
    end
  end

  test "queries can check the ammount of elements" do
    {:ok, session} = Wallaby.start_session

    assert_raise Wallaby.QueryError, fn ->
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(css(".user"))
    end

    elements =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(css(".user", count: 5))

    assert Enum.count(elements) == 5
  end

  test "queries can specify element text" do
    {:ok, session} = Wallaby.start_session

    assert_raise Wallaby.QueryError, fn ->
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(css(".user", text: "Some fake text"))
    end

    element =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(css(".user", text: "Chris K."))

    assert element
  end

  test "trying to set a text when visible is false throws an error" do
    {:ok, session} = Wallaby.start_session

    assert_raise Wallaby.QueryError, fn ->
      session
      |> Browser.find(css(".some-css", text: "test", visible: false))
    end
  end

  test "queries can be retried" do
    {:ok, session} = Wallaby.start_session

    element =
      session
      |> Browser.visit("/wait.html")
      |> Browser.find(css(".main"))

    assert element

    elements =
      session
      |> Browser.find(css(".orange", count: 5))

    assert Enum.count(elements) == 5
  end

  test "queries can find an element by only text" do
    {:ok, session} = Wallaby.start_session

    element =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(text("Chris K."))

    assert element
  end

  test "all returns an empty list if nothing is found" do
    {:ok, session} = Wallaby.start_session

    elements =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.all(css(".not_there"))

    assert Enum.count(elements) == 0

    elements =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.all(".not_there")

    assert Enum.count(elements) == 0
  end

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
