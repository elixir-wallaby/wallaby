defmodule Wallaby.Integration.LocalStorageTest do
  use ExUnit.Case, async: false

  use Wallaby.DSL

  @get_value_script "return localStorage.getItem('test')"
  @set_value_script "localStorage.setItem('test', 'foo')"

  setup_all _tags do
    {:ok, server} = Wallaby.TestServer.start

    on_exit fn ->
      Wallaby.TestServer.stop(server)
    end

    {:ok, %{server: server}}
  end

  @tag :focus
  test "local storage is not shared between sessions", %{server: server} do

    # Checkout all sessions
    {:ok, session}  = Wallaby.start_session
    {:ok, s2}       = Wallaby.start_session
    {:ok, s3}       = Wallaby.start_session

    session
    |> visit(server.base_url <> "index.html")
    |> execute_script(@set_value_script)

    assert session
    |> execute_script(@get_value_script) == "foo"

    assert s2
    |> visit(server.base_url <> "index.html")
    |> execute_script(@get_value_script) == nil

    assert s3
    |> visit(server.base_url <> "index.html")
    |> execute_script(@get_value_script) == nil

    Wallaby.end_session(session)
    {:ok, new_session} = Wallaby.start_session

    assert session.server == new_session.server

    assert new_session
    |> visit(server.base_url <> "index.html")
    |> execute_script(@get_value_script) == nil
  end
end
