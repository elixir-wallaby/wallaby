defmodule Wallaby.Integration.BrowserTest do
  use Wallaby.Integration.SessionCase, async: true

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
