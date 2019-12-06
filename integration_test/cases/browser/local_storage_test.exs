defmodule Wallaby.Integration.Browser.LocalStorageTest do
  use ExUnit.Case, async: false
  import Wallaby.Integration.SessionCase, only: [start_test_session: 0]

  use Wallaby.DSL

  @get_value_script "return localStorage.getItem('test')"
  @set_value_script "localStorage.setItem('test', 'foo')"

  @tag :skip_test_session
  test "local storage is not shared between sessions" do
    # Checkout all sessions
    {:ok, session} = start_test_session()
    {:ok, s2} = start_test_session()
    {:ok, s3} = start_test_session()

    session
    |> visit("index.html")
    |> execute_script(@set_value_script)

    session
    |> execute_script(@get_value_script, fn value -> send(self(), {:result, value}) end)

    assert_received {:result, "foo"}

    s2
    |> visit("index.html")
    |> execute_script(@get_value_script, fn value -> send(self(), {:callback, value}) end)

    assert_received {:callback, nil}

    s3
    |> visit("index.html")
    |> execute_script(@get_value_script, fn value -> send(self(), {:callback2, value}) end)

    assert_received {:callback2, nil}

    Wallaby.end_session(session)
    {:ok, new_session} = start_test_session()

    assert session.server == new_session.server

    new_session
    |> visit("index.html")
    |> execute_script(@get_value_script, fn value -> send(self(), {:callback3, value}) end)

    assert_received {:callback3, nil}
  end
end
