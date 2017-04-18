defmodule Wallaby.BrowserTest do
  use ExUnit.Case, async: true

  alias Wallaby.Browser

  describe "retry/2" do
    test "returns a valid result" do
      assert Browser.retry(fn -> {:ok, []} end) == {:ok, []}
    end

    test "it retries if the dom element is stale" do
      {:ok, agent} = Agent.start_link(fn -> {:error, :stale_reference} end)

      run_query = fn ->
        Agent.get_and_update(agent, fn initial ->
            {initial, {:ok, []}}
        end)
      end

      assert Browser.retry run_query
    end

    test "it retries until time runs out" do
      assert Browser.retry(fn -> {:error, :some_error} end) == {:error, :some_error}
    end
  end
end
