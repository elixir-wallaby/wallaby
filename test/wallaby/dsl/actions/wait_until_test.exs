defmodule Wallaby.Actions.WaitUntilTest do
  use Wallaby.SessionCase, async: true
  use Wallaby.DSL
  alias Wallaby.Node.Query

  test "wait until `find` is satisfied", %{server: server, session: session} do
    updated_session =
      session
        |> visit(server.base_url <> "wait_until.html")
        |> wait_until(& find(&1, ".main"))

    assert has_css?(updated_session, ".main"), "waited until selector became present"
    assert has_css?(updated_session, "html"), "has not narrowed scope"
  end

  test "wait until `Query.link` is satisfied", %{server: server, session: session} do
    updated_session =
      session
        |> visit(server.base_url <> "wait_until.html")
        |> wait_until(& Query.link(&1, "a", text: "a link"))

    html_root = updated_session |> find("body")

    assert has_text?(html_root, "a link"), "waited until text became present"
    assert has_css?(updated_session, "html"), "has not narrowed scope"
  end
end
