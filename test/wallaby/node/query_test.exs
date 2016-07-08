defmodule Wallaby.Node.QueryTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "forms.html")

    {:ok, page: page}
  end

  test "find_field/3 checks for labels without for attributes", %{page: page} do
    assert_raise Wallaby.BadHTML, fn ->
      fill_in(page, "Input with bad label", with: "Test")
    end
  end

  test "find_field/3 checks for mismatched ids on labels", %{page: page} do
    assert_raise Wallaby.BadHTML, fn ->
      fill_in(page, "Input with bad id", with: "Test")
    end
  end

  test "find returns not found if the element could not be found", %{page: page} do
    assert_raise Wallaby.ElementNotFound, "Could not find a button that matched: 'Test Button'\n", fn ->
      click_on page, "Test Button"
    end
  end

  test "find returns not found if the css could not be found", %{page: page} do
    assert_raise Wallaby.ElementNotFound, "Could not find an element with the css that matched: '.test-css'\n", fn ->
      find page, ".test-css"
    end
  end

  test "find returns not found if the xpath could not be found", %{page: page} do
    assert_raise Wallaby.ElementNotFound, "Could not find an element with an xpath that matched: '//test-element'\n", fn ->
      find page, {:xpath, "//test-element"}
    end
  end

  test "find/3 finds invisible elements", %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "page_1.html")

    assert find(page, "#invisible", visible: false)
  end

  test "find/3 throws errors if element should not be visible", %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "page_1.html")

    assert_raise Wallaby.VisibleElement, fn ->
      find(page, "#visible", visible: false)
    end
  end
end
