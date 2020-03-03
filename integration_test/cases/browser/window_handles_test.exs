defmodule Wallaby.Integration.Browser.WindowHandlesTest do
  use Wallaby.Integration.SessionCase, async: true

  test "switching between tabs and windows", %{session: session} do
    session
    |> visit("windows.html")

    initial_handle = window_handle(session)
    assert [initial_handle] == window_handles(session)

    session
    |> click(Query.link("New tab"))

    :timer.sleep(500)

    handles = window_handles(session)
    assert length(handles) == 2

    new_tab_handle = Enum.find(handles, fn handle -> handle != initial_handle end)
    focus_window(session, new_tab_handle)

    assert new_tab_handle == window_handle(session)
    assert_has(session, Query.css("h1", text: "Page 1"))

    session
    |> focus_window(initial_handle)
    |> click(Query.link("New window"))

    :timer.sleep(500)

    handles2 = window_handles(session)
    assert length(handles2) == 3

    new_window_handle =
      Enum.find(handles2, fn handle -> handle not in [initial_handle, new_tab_handle] end)

    focus_window(session, new_window_handle)

    assert new_window_handle == window_handle(session)
    assert_has(session, Query.css("h1", text: "Page 2"))
  end

  test "closing tabs and windows", %{session: session} do
    session
    |> visit("windows.html")

    initial_handle = window_handle(session)

    session
    |> click(Query.link("New tab"))

    :timer.sleep(500)

    new_tab_handle = Enum.find(window_handles(session), fn handle -> handle != initial_handle end)

    session
    |> focus_window(new_tab_handle)
    |> close_window()
    |> focus_window(initial_handle)

    assert [initial_handle] == window_handles(session)

    session
    |> click(Query.link("New window"))

    :timer.sleep(500)

    new_window_handle =
      Enum.find(window_handles(session), fn handle -> handle != initial_handle end)

    session
    |> focus_window(new_window_handle)
    |> close_window()
    |> focus_window(initial_handle)

    assert [initial_handle] == window_handles(session)
  end
end
