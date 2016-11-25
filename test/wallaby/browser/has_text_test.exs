defmodule Wallaby.Browser.HasTextTest do
  use Wallaby.SessionCase, async: true

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
  end
end
