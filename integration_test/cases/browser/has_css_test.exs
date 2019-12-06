defmodule Wallaby.Integration.Browser.HasCssTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "page_1.html")
    {:ok, %{page: page}}
  end

  describe "has_css/2" do
    test "checks if the query has the specified text", %{page: page} do
      assert page
             |> has_css?(".user")
    end
  end

  describe "has_no_css/2" do
    test "checks that there is no visible matching css", %{page: page} do
      assert page
             |> has_no_css?("#invisible")
    end
  end
end
