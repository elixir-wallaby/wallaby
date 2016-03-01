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

  test "nonexisting elements are not found", %{server: server, session: session} do
    element =
      session
      |> visit(server.base_url)
      |> find("#not-there")

    refute element
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
end
