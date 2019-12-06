defmodule Wallaby.Integration.Browser.PageSourceTest do
  use Wallaby.Integration.SessionCase, async: true

  test "page_source/1 retrieves the source of the current page", %{session: session} do
    source =
      session
      |> visit("/index.html")
      |> page_source
      |> clean_up_html

    actual_html =
      "integration_test/support/pages/index.html"
      |> Path.absname()
      |> File.read!()
      |> clean_up_html

    # Firefox inserts a <!doctype html> so you can't do an exact comparison
    assert actual_html =~ source
  end

  def clean_up_html(string) do
    string
    |> String.replace(~r/\s+/, "")
    |> String.downcase()
  end
end
