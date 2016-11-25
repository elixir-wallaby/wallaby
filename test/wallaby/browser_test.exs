defmodule Wallaby.BrowserTest do
  use Wallaby.SessionCase, async: true

  alias Wallaby.Query

  describe "retry/2" do
    test "returns a valid result" do
      assert retry(fn -> {:ok, []} end) == {:ok, []}
    end

    test "it retries if the dom element is stale" do
      {:ok, agent} = Agent.start_link(fn -> {:error, :stale_reference} end)

      run_query = fn ->
        Agent.get_and_update(agent, fn initial ->
            {initial, {:ok, []}}
        end)
      end

      assert retry run_query
    end

    test "it retries until time runs out" do
      assert retry(fn -> {:error, :some_error} end) == {:error, :some_error}
    end
  end

  describe "has?/2" do
    test "allows css queries", %{session: session} do
      session
      |> visit("/page_1.html")
      |> has?(Query.css(".blue"))
      |> assert
    end

    test "allows text queries", %{session: session} do
      session
      |> visit("/page_1.html")
      |> has?(Query.text("Page 1"))
      |> assert
    end
  end
end
