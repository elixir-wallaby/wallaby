defmodule Wallaby.NodeTest do
  use Wallaby.SessionCase, async: true
  use Wallaby.DSL

  test "can find an element on a page", %{server: server, session: session} do
    element =
      session
      |> visit(server.base_url)
      |> find("#header")

    assert element
  end

  test "finding nonexistent elements raises an exception", %{server: server, session: session} do
    assert_raise Wallaby.QueryError, fn ->
      session
      |> visit(server.base_url)
      |> find("#not-there")
    end
  end

  test "ambiguous queries raise an exception", %{server: server, session: session} do
    assert_raise Wallaby.QueryError, fn ->
      session
      |> visit(server.base_url)
      |> find("a")
    end
  end

  test "can query for multiple elements", %{server: server, session: session} do
    elements =
      session
      |> visit(server.base_url)
      |> all("a")

    assert length(elements) == 3
  end

  test "queries can be scoped to nodes", %{server: server, session: session} do
    users =
      session
      |> visit(server.base_url <> "nesting.html")
      |> find(".dashboard")
      |> find(".users")
      |> all(".user")

    assert Enum.count(users) == 3
    assert List.first(users) |> text == "Chris"
  end

  test "empty list is returned when all does not match", %{server: server, session: session} do
    elements =
      session
      |> visit(server.base_url)
      |> all("table")

    assert elements == []
  end

  test "can get text of an element", %{server: server, session: session} do
    text =
      session
      |> visit(server.base_url)
      |> find("#header")
      |> text

    assert text == "Test Index"
  end

  test "can get text of an element and its descendants", %{server: server, session: session} do
    text =
      session
      |> visit(server.base_url)
      |> find("#parent")
      |> text

    assert text == "The Parent\nThe Child"
  end

  test "has_text?/2 waits for presence of text and returns a bool", %{server: server, session: session} do
    node =
    session
      |> visit(server.base_url <> "wait.html")
      |> find("#container")

    assert has_text?(node, "main")
    refute has_text?(node, "rain")
  end

  test "assert_text/2 waits for presence of text and and returns true if found", %{server: server, session: session} do
    node =
    session
      |> visit(server.base_url <> "wait.html")
      |> find("#container")

    assert assert_text(node, "main")
  end

  test "assert_text/2 will raise an exception for text not found", %{server: server, session: session} do
    node =
    session
      |> visit(server.base_url <> "wait.html")
      |> find("#container")

    assert_raise Wallaby.ExpectationNotMet, "Text 'rain' not found", fn ->
      assert_text(node, "rain")
    end
  end

  test "can get attributes of an element", %{server: server, session: session} do
    class =
      session
      |> visit(server.base_url)
      |> find("body")
      |> attr("class")

    assert class == "bootstrap"
  end

  test "clearing input", %{server: server, session: session} do
    node =
      session
      |> visit(server.base_url <> "forms.html")
      |> find("#name_field")

    fill_in(node, with: "Chris")
    assert has_value?(node, "Chris")

    clear(node)
    refute has_value?(node, "Chris")
    assert has_value?(node, "")
  end

  test "waits for an element to be visible", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "wait.html")

    assert all(session, ".main") == []

    assert find(session, ".main")
  end

  test "waits for count elements to be visible", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "wait.html")

    assert all(session, ".orange") == []

    assert find(session, ".orange", count: 5) |> length == 5
  end

  test "finding one or more elements", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "page_1.html")

    assert_raise Wallaby.QueryError, fn ->
      find(session, ".not-there", count: :any)
    end

    assert find(session, "li", count: :any) |> length == 4
  end

  test "has_css/2 returns true if the css is on the page", %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "nesting.html")

    assert has_css?(page, ".user")
  end

  test "has_no_css/2 checks is the css is not on the page", %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "nesting.html")

    assert has_no_css?(page, ".something_else")
  end

  test "has_no_css/2 raises error if the css is found", %{session: session, server: server} do
    assert_raise Wallaby.QueryError, fn ->
      session
      |> visit(server.base_url <> "nesting.html")
      |> has_no_css?(".user")
    end
  end

  test "executing scripts with arguments and returning", %{session: session, server: server} do
    script = """
      var node = document.createElement("div")
      node.id = "new-element"
      var text = document.createTextNode(arguments[0])
      node.appendChild(text)
      document.body.appendChild(node)
      return arguments[1]
    """

    result =
      session
      |> visit(server.base_url <> "page_1.html")
      |> execute_script(script, ["now you see me", "return value"])

    assert result == "return value"
    assert find(session, "#new-element") |> text == "now you see me"
  end

  test "sending text", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")

    session
    |> find("#name_field")
    |> click

    session
    |> send_text("hello")

    assert session |> find("#name_field") |> has_value?("hello")
  end

  test "sending key presses", %{session: session, server: server} do
    session
    |> visit(server.base_url)

    session
    |> send_keys([:tab, :enter])

    assert find(session, ".blue")
  end

  test "find/2 raises an error if the element is not visible", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "page_1.html")

    assert_raise Wallaby.QueryError, fn ->
      find(session, "#invisible", count: :any)
    end

    assert find(session, "#visible", count: :any) |> length == 1
  end

  describe "visible?/1" do
    setup :visit_page

    test "determines if the node is visible to the user", %{page: page} do
      page
      |> find("#visible")
      |> visible?
      |> assert

      page
      |> find("#invisible", visible: false)
      |> visible?
      |> refute
    end

    test "handles elements that are not on the page", %{page: page} do
      node = find(page, "#off-the-page", visible: false)

      assert visible?(node) == false
    end

    @tag skip: "Unsuported in phantom"
    test "handles obscured elements", %{page: page} do
      node = find(page, "#obscured", visible: false)

      assert visible?(node) == false
    end
  end

  def visit_page(%{session: session, server: server}) do
    page =
      session
      |> visit(server.base_url <> "page_1.html")

    {:ok, page: page}
  end
end
