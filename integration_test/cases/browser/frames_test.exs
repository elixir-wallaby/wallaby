defmodule Wallaby.Integration.Browser.FramesTest do
  use Wallaby.Integration.SessionCase, async: true

  test "switching between frames", %{session: session} do
    session
    |> visit("frames.html")
    |> assert_has(Query.css("h1", text: "Frames Page"))
    |> assert_has(Query.css("h1", text: "Page 1", count: 0))
    |> assert_has(Query.css("h1", text: "Page 2", count: 0))
    |> focus_frame(Query.css("#frame1"))
    |> assert_has(Query.css("h1", text: "Frames Page", count: 0))
    |> assert_has(Query.css("h1", text: "Page 1"))
    |> assert_has(Query.css("h1", text: "Page 2", count: 0))
    |> focus_parent_frame()
    |> focus_frame(Query.css("#frame2"))
    |> assert_has(Query.css("h1", text: "Frames Page", count: 0))
    |> assert_has(Query.css("h1", text: "Page 1", count: 0))
    |> assert_has(Query.css("h1", text: "Page 2"))
    |> focus_default_frame()
    |> assert_has(Query.css("h1", text: "Frames Page"))
    |> assert_has(Query.css("h1", text: "Page 1", count: 0))
    |> assert_has(Query.css("h1", text: "Page 2", count: 0))
  end
end
