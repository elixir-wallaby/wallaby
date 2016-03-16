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
end
