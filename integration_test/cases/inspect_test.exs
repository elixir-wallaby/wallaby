defmodule Wallaby.Integration.InspectTest do
  use Wallaby.Integration.SessionCase, async: true
  import ExUnit.CaptureIO

  describe "inspect/2" do
    test "prints the outerHTML of the element", %{session: session} do
      expected =
        """
        #{IO.ANSI.cyan()}outerHTML:

        #{IO.ANSI.reset()}#{IO.ANSI.yellow()}<body class="bootstrap index-page">
          <h1 id="header">Test Index</h1>
          <ul>
            <li><a href="page_1.html">Page 1</a></li>
            <li><a href="page_2.html">Page 2</a></li>
            <li><a href="page_3.html">Page 3</a></li>
          </ul>

          <div id="parent">
            The Parent
            <div id="child">
              The Child
            </div>
          </div>
        </body>#{IO.ANSI.reset()}
        """
        |> String.replace(~r/\s/, "")

      actual =
        capture_io(fn ->
          session
          |> visit("/index.html")
          |> find(Query.css("body"))
          |> IO.inspect()
        end)
        |> String.replace(~r/\s/, "")

      IO.puts(actual)

      assert actual =~ expected
    end

    test "doesn't fail when request to fetch outerHTML fails", %{session: session} do
      actual =
        capture_io(fn ->
          element =
            session
            |> visit("/index.html")
            |> find(Query.css("body"))

          Wallaby.end_session(session)

          element
          |> IO.inspect()
        end)
        |> String.replace(~r/\s/, "")

      refute actual =~ "outerHTML:"
    end
  end
end
