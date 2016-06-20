defmodule Wallaby.Finders.TitleTest do
  use Wallaby.ServerCase, async: true
  use Wallaby.DSL

  setup do
    {:ok, session} = Wallaby.start_session

    on_exit fn ->
      Wallaby.end_session(session)
    end

    {:ok, %{session: session}}
  end

  test "finding the title", %{server: server, session: session} do
    text =
      session
      |> visit(server.base_url)
      |> page_title

    assert text == "Test Index"
  end
end
