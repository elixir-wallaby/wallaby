defmodule Wallaby.Session.PageSourceTest do
  use Wallaby.SessionCase, async: true

  test "page_source/1 retrieves the source of the current page", %{session: session, server: server} do
    source =
      session
      |> visit(server.base_url <> "/index.html")
      |> page_source
      |> clean_up_html

    actual_html =
      "test/support/pages/index.html"
      |> Path.absname()
      |> File.read!
      |> clean_up_html

    assert source == actual_html
  end

  def clean_up_html(string) do
    string
    |> String.replace(~r/\s+/, "")
    |> String.downcase
  end
end
