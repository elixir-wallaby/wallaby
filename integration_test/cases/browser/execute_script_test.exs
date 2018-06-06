defmodule Wallaby.Integration.Browser.ExecuteScriptTest do
  use Wallaby.Integration.SessionCase, async: true

  @script """
    var element = document.createElement("div")
    element.id = "new-element"
    var text = document.createTextNode(arguments[0])
    element.appendChild(text)
    document.body.appendChild(element)
    return arguments[1]
  """
  test "executing scripts with arguments and returning", %{session: session} do

    assert session
      |> visit("page_1.html")
      |> execute_script(@script, ["now you see me", "return value"])
      |> find(Query.css("#new-element"))
      |> Element.text == "now you see me"
  end

  test "executing scripts with arguments and callback returns session", %{session: session} do
    result =
      session
      |> visit("page_1.html")
      |> execute_script(@script, ["now you see me", "return value"], fn(value) ->
           assert value == "return value"
           send self(), {:callback, value}
         end)

    assert result == session

    assert_received{:callback, "return value"}

    assert session
    |> find(Query.css("#new-element"))
    |> Element.text == "now you see me"
  end

  test "executing scripts asynchronously with arguments and returning", %{session: session} do
    assert session
      |> visit("page_1.html")
      |> execute_script_async(@script, ["now you see me", "return value"])
      |> find(Query.css("#new-element"))
      |> Element.text == "now you see me"
  end

  test "executing scripts asynchronously with arguments and callback returns session", %{session: session} do
    result =
      session
      |> visit("page_1.html")
      |> execute_script_async(@script, ["now you see me", "return value"], fn(value) ->
           assert value == "return value"
           send self(), {:callback, value}
         end)

    assert result == session
    assert_received{:callback, "return value"}
    assert session
    |> find(Query.css("#new-element"))
    |> Element.text == "now you see me"
  end




end
