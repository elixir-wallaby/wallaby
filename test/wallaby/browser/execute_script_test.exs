defmodule Wallaby.Browser.ExecuteScriptTest do
  use Wallaby.SessionCase, async: true

  test "executing scripts with arguments and returning", %{session: session} do
    script = """
      var element = document.createElement("div")
      element.id = "new-element"
      var text = document.createTextNode(arguments[0])
      element.appendChild(text)
      document.body.appendChild(element)
      return arguments[1]
    """

    result =
      session
      |> visit("page_1.html")
      |> execute_script(script, ["now you see me", "return value"])

    assert result == "return value"
    assert session
    |> find("#new-element")
    |> text == "now you see me"
  end
end
