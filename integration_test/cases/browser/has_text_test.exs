defmodule Wallaby.Integration.Browser.HasTextTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "page_1.html")
    {:ok, %{page: page}}
  end

  @h1 Query.css("h1")

  describe "has_text/3" do
    test "checks if the query has the specified text", %{page: page} do
      assert page
             |> has_text?(@h1, "Page 1")
    end
  end

  describe "has_text/2" do
    test "checks if the element has the specified text", %{page: page} do
      assert page
             |> find(@h1)
             |> has_text?("Page 1")
    end

    test "matches all text under the element", %{page: page} do
      assert page
             |> find(Query.css(".lots-of-text"))
             |> has_text?("Text 2")
    end

    test "works with sessions", %{page: page} do
      assert page
             |> has_text?("Page 1")
    end

    test "retries the query", %{page: page} do
      assert page
             |> visit("wait.html")
             |> has_text?("orange") == true
    end
  end
end
