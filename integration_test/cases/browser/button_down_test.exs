defmodule Wallaby.Integration.Browser.ButtonDownTest do
  use Wallaby.Integration.SessionCase, async: true
  import Wallaby.Browser

  setup %{session: session} do
    {:ok, page: visit(session, "mouse_down_and_up.html")}
  end

  describe "button_down/2" do
    test "clicks and holds left mouse button at the current cursor position", %{page: page} do
      button_down_test(page, :left, "Left")
    end

    test "clicks and holds middle mouse button at the current cursor position", %{page: page} do
      button_down_test(page, :middle, "Middle")
    end

    test "clicks and holds right mouse button at the current cursor position", %{page: page} do
      button_down_test(page, :right, "Right")
    end
  end

  defp button_down_test(page, button, expected_log_prefix) do
    refute page
           |> visible?(Query.text("#{expected_log_prefix} Down"))

    assert page
           |> hover(Query.text("Button 1"))
           |> button_down(button)
           |> visible?(Query.text("#{expected_log_prefix} Down"))

    refute page
           |> visible?(Query.text("#{expected_log_prefix} Up"))
  end
end
