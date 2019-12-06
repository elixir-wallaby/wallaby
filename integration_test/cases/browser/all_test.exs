defmodule Wallaby.Integration.Browser.AllTest do
  use Wallaby.Integration.SessionCase, async: true

  describe "all/2" do
    setup %{session: session} do
      page = visit(session, "index.html")

      {:ok, %{page: page}}
    end

    test "returns all of the elements matching the query", %{page: page} do
      assert page
             |> all(Query.css("li"))
             |> Enum.count() == 3
    end
  end
end
