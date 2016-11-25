defmodule Wallaby.Phantom.Driver.JSErrorsTest do
  use Wallaby.SessionCase, async: true

  import ExUnit.CaptureIO

  test "it captures javascript errors", %{session: session} do
    assert_raise Wallaby.JSError, fn ->
      session
      |> visit("/errors.html")
      |> click_button("Throw an Error")
    end
  end

  test "it captures javascript console logs", %{session: session} do
    fun = fn ->
      session
      |> visit("/logs.html")
    end
    assert capture_io(fun) == "Capture console logs\n"
  end

  test "it only captures logs once", %{session: session} do
    output = """
    Capture console logs
    Button clicked
    """

    fun = fn ->
      session
      |> visit("/logs.html")
      |> click_button("Print Log")
    end

    assert capture_io(fun) == output
  end
end
