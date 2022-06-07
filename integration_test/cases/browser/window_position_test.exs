defmodule Wallaby.Integration.Browser.WindowPositionTest do
  use Wallaby.Integration.SessionCase, async: true

  # this test dows not return the right values on mac
  # reason is unclear, I think it's a bug in chromedriver on mac
  if :os.type() != {:unix, :darwin} do
    test "getting the window position", %{session: session} do
      window_position =
        session
        |> visit("/")
        |> move_window(100, 200)
        |> window_position()

      assert %{"x" => 100, "y" => 200} = window_position
    end
  end
end
