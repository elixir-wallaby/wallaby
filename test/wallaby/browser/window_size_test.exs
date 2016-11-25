defmodule Wallaby.Browser.WindowSizeTest do
  use Wallaby.SessionCase, async: true

  test "getting the window size", %{session: session} do
    window_size =
      session
      |> visit("/")
      |> resize_window(1234, 1234)
      |> window_size

    assert window_size == %{"height" => 1234, "width" => 1234}
  end
end
