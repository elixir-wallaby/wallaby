defmodule Wallaby.DSL.Finders.FindTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "forms.html")

    {:ok, page: page}
  end

  describe "find/3" do
    setup %{session: session, server: server} do
      page =
        session
        |> visit(server.base_url <> "page_1.html")

      {:ok, page: page}
    end

    test "throws errors if element should not be visible", %{page: page} do
      assert_raise Wallaby.QueryError, fn ->
        find(page, "#visible", visible: false)
      end
    end

    test "throws a not found error if the element could not be found", %{page: page} do
      assert_raise Wallaby.QueryError, "Could not find any visible button that matched: 'Test Button'", fn ->
        click_on page, "Test Button"
      end
    end

    test "throws a not found error if the css could not be found", %{page: page} do
      assert_raise Wallaby.QueryError, "Could not find any visible element with css that matched: '.test-css'", fn ->
        find page, ".test-css"
      end
    end

    test "throws a not found error if the xpath could not be found", %{page: page} do
      assert_raise Wallaby.QueryError, "Could not find any visible element with an xpath that matched: '//test-element'", fn ->
        find page, {:xpath, "//test-element"}
      end
    end

    test "find/3 finds invisible elements", %{page: page} do
      assert find(page, "#invisible", visible: false)
    end

    test "can be scoped with inner text", %{page: page} do
      user1 = find(page, ".user", text: "Chris K.")
      user2 = find(page, ".user", text: "Grace H.")
      assert user1 != user2
    end

    test "can be scoped by inner text when there are multiple elements with text", %{page: page} do
      element = find(page, ".inner-text", text: "Inner Text")
      assert element
    end

    test "scoping with text escapes the text", %{page: page} do
      assert find(page, ".plus-one", text: "+ 1")
    end

    test "scopes can be composed together", %{page: page} do
      assert find(page, ".user", text: "Same User", count: 2)
      assert find(page, ".user", text: "Visible User", visible: true)
      assert find(page, ".invisible-elements", visible: false, count: 3)
    end
  end
end
