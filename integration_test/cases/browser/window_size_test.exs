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

  describe "default window size" do
    setup do
      {:ok, session} = start_test_session(window_size: [width: 600, height: 400])

      {:ok, %{session: session}}
    end

    @tag :skip_test_session
    test "sets window size from config option", %{session: session} do
      window_size =
        session
        |> visit("/")
        |> window_size

      assert %{"height" => 400, "width" => 600} = window_size
    end
  end
end
