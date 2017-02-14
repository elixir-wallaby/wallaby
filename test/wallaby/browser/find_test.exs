defmodule Wallaby.Browser.FindTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session} do
    page =
      session
      |> visit("forms.html")

    {:ok, page: page}
  end

  describe "find/3" do
    setup %{session: session} do
      page =
        session
        |> visit("page_1.html")

      {:ok, page: page}
    end

    test "can find an element on a page", %{session: session} do
      element =
        session
        |> find(Query.css(".blue"))

      assert element
    end

    test "queries can be scoped by elements", %{session: session} do
      users =
        session
        |> visit("nesting.html")
        |> find(Query.css(".dashboard"))
        |> find(Query.css(".users"))
        |> all(".user")

      assert Enum.count(users) == 3
      assert List.first(users) |> text == "Chris"
    end

    test "throws a not found error if the element could not be found", %{page: page} do
      assert_raise Wallaby.QueryError, ~r/Expected to find/, fn ->
        find(page, Query.css("#not-there"))
      end
    end

    test "throws a not found error if the xpath could not be found", %{page: page} do
      assert_raise Wallaby.QueryError, ~r/Expected (.*) xpath '\/\/test-element'/, fn ->
        find page, Query.xpath("//test-element")
      end
    end

    test "ambiguous queries raise an exception", %{page: page} do
      assert_raise Wallaby.QueryError, ~r/Expected (.*) 1(.*) but 5/, fn ->
        find page, Query.css(".user")
      end
    end

    test "throws errors if element should not be visible", %{page: page} do
      assert_raise Wallaby.QueryError, ~r/invisible/, fn ->
        find(page, Query.css("#visible", visible: false))
      end
    end

    test "find/2 raises an error if the element is not visible", %{session: session} do
      session
      |> visit("page_1.html")

      assert_raise Wallaby.QueryError, fn ->
        find(session, "#invisible")
      end

      assert find(session, Query.css("#visible", count: :any))
      |> length == 1
    end

    test "finds invisible elements", %{page: page} do
      assert find(page, Query.css("#invisible", visible: false))
    end

    test "can be scoped with inner text", %{page: page} do
      user1 = find(page, Query.css(".user", text: "Chris K."))
      user2 = find(page, Query.css(".user", text: "Grace H."))
      assert user1 != user2
    end

    test "can be scoped by inner text when there are multiple elements with text", %{page: page} do
      element = find(page, Query.css(".inner-text", text: "Inner Text"))
      assert element
    end

    test "scoping with text escapes the text", %{page: page} do
      assert find(page, Query.css(".plus-one", text: "+ 1"))
    end

    test "scopes can be composed together", %{page: page} do
      assert find(page, Query.css(".user", text: "Same User", count: 2))
      assert find(page, Query.css(".user", text: "Visible User", visible: true))
      assert find(page, Query.css(".invisible-elements", visible: false, count: 3))
    end
  end

  test "waits for an element to be visible", %{session: session} do
    session
    |> visit("wait.html")

    assert find(session, ".main")
  end

  test "waits for count elements to be visible", %{session: session} do
    session
    |> visit("wait.html")

    assert find(session, Query.css(".orange", count: 5)) |> length == 5
  end

  test "finding one or more elements", %{session: session} do
    session
    |> visit("page_1.html")

    assert_raise Wallaby.QueryError, fn ->
      find(session, ".not-there")
    end

    assert find(session, Query.css("li", count: :any)) |> length == 4
  end

  describe "find/3" do
    setup %{session: session} do
      page = visit(session, "page_1.html")

      {:ok, %{page: page}}
    end

    @tag :focus
    test "returns the element as the argument to the callback", %{page: page} do
      page
      |> find(Query.css("h1"), & assert has_text?(&1, "Page 1") )
    end

    @tag :focus
    test "returns the parent", %{page: page} do
      assert page
      |> find(Query.css("h1"), fn(_) -> nil end) == page
    end
  end
end
