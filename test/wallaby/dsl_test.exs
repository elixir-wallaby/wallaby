defmodule Wallaby.DSLTest do
  use Wallaby.ServerCase, async: true

  use Wallaby.DSL

  setup do
    {:ok, session} = Wallaby.start_session
    {:ok, %{session: session}}
  end

  test "can find an element on a page", %{server: server, session: session} do
    element =
      session
      |> visit(server.base_url)
      |> find("#header")

    assert element
  end

  test "finding nonexistent elements raises an exception", %{server: server, session: session} do
    assert_raise Wallaby.ElementNotFound, fn ->
      session
      |> visit(server.base_url)
      |> find("#not-there")
    end
  end

  test "ambiguous queries raise an exception", %{server: server, session: session} do
    assert_raise Wallaby.AmbiguousMatch, fn ->
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

  test "has_content?/2 asserts text in an element", %{server: server, session: session} do
    node =
      session
      |> visit(server.base_url)
      |> find("#header")

    assert has_content?(node, "Test Index")
  end

  test "can get attributes of an element", %{server: server, session: session} do
    class =
      session
      |> visit(server.base_url)
      |> find("body")
      |> attr("class")

    assert class == "bootstrap"
  end

  test "click through to another page", %{server: server, session: session} do
    session
    |> visit(server.base_url)
    |> click_link("Page 1")

    element =
      session
      |> find(".blue")

    assert element
  end

  test "filling in input by name", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name", with: "Chris")

    assert find(session, "#name_field") |> has_value?("Chris")
  end

  test "filling in input by id", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Chris")

    assert find(session, "#name_field") |> has_value?("Chris")
  end

  test "filling in multple inputs", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name", with: "Alex")
    |> fill_in("email", with: "alex@example.com")

    assert find(session, "#name_field")  |> has_value?("Alex")
    assert find(session, "#email_field") |> has_value?("alex@example.com")
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

  test "choosing a radio button", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")
    |> choose("option2")

    assert find(session, "#option2") |> checked?
  end

  test "choosing a radio button unchecks other buttons in the group", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")

    choose(session, "Option 1")
    assert find(session, "#option1") |> checked?

    find(session, "#option2")
    |> choose()

    refute find(session, "#option1") |> checked?
    assert find(session, "#option2") |> checked?
  end

  test "navigating by path only", %{session: session, server: server} do
    Application.put_env(:wallaby, :base_url, server.base_url)
    session
    |> visit("page_1.html")

    element =
      session
      |> find(".blue")

    assert element
    Application.put_env(:wallaby, :base_url, nil)
  end

  test "taking a screenshot", %{session: session, server: server} do
    path =
      session
      |> visit(server.base_url)
      |> take_screenshot

    assert File.exists? path
    File.rm_rf! "#{File.cwd!}/screenshots"
  end

  test "manipulating window size", %{session: session, server: server} do
    window_size =
      session
      |> visit(server.base_url)
      |> set_window_size(1234, 1234)
      |> get_window_size

    assert window_size == %{"height" => 1234, "width" => 1234}
  end
end
