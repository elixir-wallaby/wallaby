defmodule Wallaby.Integration.Browser.StaleElementsTest do
  use Wallaby.Integration.SessionCase, async: true

  describe "when a DOM element becomes stale" do
    test "the query is retried", %{session: session} do
      element =
        session
        |> visit("stale_nodes.html")
        |> find(Query.css(".stale-node", text: "Stale", count: 1))

      assert element
    end

    test "when a DOM element disappears", %{session: session} do
      element =
        session
        |> visit("stale_nodes.html")
        |> find(Query.css("#removed-node"))

      Process.sleep(400) # let the node disappear via javascript

      assert_raise Wallaby.StaleReferenceException, fn ->
        Element.value(element)
      end
    end
  end
end
