defmodule Wallaby.DSL.Finders.TitleTest do
  use Wallaby.SessionCase, async: true
  use Wallaby.DSL

  test "finding the title", %{server: server, session: session} do
    text =
      session
      |> visit(server.base_url)
      |> page_title

    assert text == "Test Index"
  end
end
