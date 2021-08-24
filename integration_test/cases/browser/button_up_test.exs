defmodule Wallaby.Integration.Browser.ButtonUpTest do
  use Wallaby.Integration.SessionCase, async: true
  import Wallaby.Browser

  setup %{session: session} do
    {:ok, page: visit(session, "mouse_down_and_up.html")}
  end

  describe "button_down/2 releases previously held mouse button at the current cursor position" do
    test "for left button", %{page: page} do
      button_up_test(page, :left, "Left")
    end

    test "for middle button", %{page: page} do
      button_up_test(page, :middle, "Middle")
    end

    test "for right button", %{page: page} do
      button_up_test(page, :right, "Right")
    end
  end

  describe "button_down/2 releases previously held mouse button if cursor is moved from the position where the button was pressed" do
    test "for left button", %{page: page} do
      move_cursor_then_button_up_test(page, :left, "Left")
    end

    test "for middle button", %{page: page} do
      move_cursor_then_button_up_test(page, :middle, "Middle")
    end

    test "for right button", %{page: page} do
      move_cursor_then_button_up_test(page, :right, "Right")
    end
  end

  defp button_up_test(page, button, expected_log_prefix) do
    refute page
           |> visible?(Query.text("#{expected_log_prefix} Up"))

    assert page
           |> hover(Query.text("Button 1"))
           |> button_down(button)
           |> button_up(button)
           |> visible?(Query.text("#{expected_log_prefix} Up"))

    refute page
           |> visible?(Query.text("#{expected_log_prefix} Down"))
  end

  defp move_cursor_then_button_up_test(page, button, expected_log_prefix) do
    refute page
           |> visible?(Query.text("#{expected_log_prefix} Up"))

    assert page
           |> hover(Query.text("Button 1"))
           |> button_down(button)
           |> hover(Query.text("Button 2"))
           |> button_up(button)
           |> visible?(Query.text("#{expected_log_prefix} Up"))

    refute page
           |> visible?(Query.text("#{expected_log_prefix} Down"))
  end
end
