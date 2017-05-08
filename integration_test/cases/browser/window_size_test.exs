defmodule Wallaby.Integration.Browser.WindowSizeTest do
  use Wallaby.Integration.SessionCase, async: true

  test "getting the window size", %{session: session} do
    window_size =
      session
      |> visit("/")
      |> resize_window(600, 400)
      |> window_size

    assert %{"height" => 400, "width" => 600} = window_size
  end
end
