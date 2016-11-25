defmodule Wallaby.Browser.StaleElementsTest do
  use Wallaby.SessionCase, async: true

  describe "when a DOM element becomes stale" do
    test "the query is retried", %{session: session} do
      element =
        session
        |> visit("stale_nodes.html")
        |> find(".stale-node", text: "Stale", count: 1)

      assert element
    end

    test "it surfaces the stale element error", %{session: session} do
      element =
        session
        |> visit("stale_nodes.html")
        |> find("#removed-node.stale-node")

      Process.sleep(1_000)

      assert_raise Wallaby.StaleReferenceException, fn ->
        text(element)
      end
    end
  end
end
