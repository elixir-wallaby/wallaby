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
           |> Element.text() == "now you see me"
  end

  test "executing scripts with arguments and callback returns session", %{session: session} do
    result =
      session
      |> visit("page_1.html")
      |> execute_script(@script, ["now you see me", "return value"], fn value ->
        assert value == "return value"
        send(self(), {:callback, value})
      end)

    assert result == session

    assert_received {:callback, "return value"}

    assert session
           |> find(Query.css("#new-element"))
           |> Element.text() == "now you see me"
  end

  test "executing asynchronous script and callback returns session", %{session: session} do
    result =
      session
      |> visit("page_1.html")
      |> execute_script_async("arguments[arguments.length - 1]('hello')", [], fn value ->
        assert value == "hello"
        send(self(), {:callback, value})
      end)

    assert result == session
    assert_received {:callback, "hello"}
  end

  test "executing asynchronous script with arguments and callback returns session", %{
    session: session
  } do
    result =
      session
      |> visit("page_1.html")
      |> execute_script_async(
        "arguments[arguments.length - 1](arguments[0]);",
        ["hello"],
        fn value ->
          assert value == "hello"
          send(self(), {:callback, value})
        end
      )

    assert result == session
    assert_received {:callback, "hello"}
  end

  test "returning element after asynchronous operation with timeout", %{session: session} do
    result =
      session
      |> visit("page_1.html")
      |> execute_script_async(
        "var callback = arguments[0]; setTimeout(function() { callback(document.getElementById('visible').innerHTML) }, 300);",
        [],
        fn value ->
          assert value == "Visible"
          send(self(), {:callback, value})
        end
      )

    assert result == session
    assert_received {:callback, "Visible"}
  end

  test "returning element after asynchronous operation", %{session: session} do
    result =
      session
      |> visit("page_1.html")
      |> execute_script_async(
        "var callback = arguments[0]; callback(document.getElementById('visible').innerHTML);",
        [],
        fn value ->
          assert value == "Visible"
          send(self(), {:callback, value})
        end
      )

    assert result == session
    assert_received {:callback, "Visible"}
  end

  test "returning element after asynchronous operation with arguments", %{session: session} do
    result =
      session
      |> visit("page_1.html")
      |> execute_script_async(
        "arguments[arguments.length - 1](document.getElementById(arguments[0]).innerHTML);",
        ["visible"],
        fn value ->
          assert value == "Visible"
          send(self(), {:callback, value})
        end
      )

    assert result == session
    assert_received {:callback, "Visible"}
  end
end
