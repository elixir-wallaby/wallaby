defmodule Wallaby.Phantom.Driver.JSErrorsTest do
  use Wallaby.SessionCase, async: true

  import ExUnit.CaptureIO

  test "it captures javascript errors", %{session: session, server: server} do
    assert_raise Wallaby.JSError, fn ->
      session
      |> visit(server.base_url <> "/errors.html")
      |> click_on("Throw an Error")
    end
  end

  test "it captures javascript console logs", %{session: session, server: server} do
    fun = fn ->
      session
      |> visit(server.base_url <> "/logs.html")
    end
    assert capture_io(fun) == "Capture console logs\n"
  end

  test "it only captures logs once", %{session: session, server: server} do
    output = """
    Capture console logs
    Button clicked
    """

    fun = fn ->
      session
      |> visit(server.base_url <> "/logs.html")
      |> click_on("Print Log")
    end

    assert capture_io(fun) == output
  end
end
