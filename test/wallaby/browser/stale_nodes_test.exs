defmodule Wallaby.Browser.StaleElementsTest do
  use Wallaby.SessionCase, async: true

  describe "when a DOM element becomes stale" do
    test "the query is retried", %{session: session} do
      element =
        session
        |> visit("stale_nodes.html")
        |> find(Query.css(".stale-node", text: "Stale", count: 1))

      assert element
    end
  end
end
