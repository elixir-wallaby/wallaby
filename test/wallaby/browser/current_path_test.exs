defmodule Wallaby.Browser.CurrentPathTest do
  use Wallaby.SessionCase, async: true

  test "gets the current_url of the session", %{session: session}  do
    url =
      session
      |> visit("")
      |> click_link("Page 1")
      |> current_url()

    assert url == "http://localhost:#{URI.parse(url).port}/page_1.html"
  end

  test "gets the current_path of the session", %{session: session}  do
    path =
      session
      |> visit("")
      |> click_link("Page 1")
      |> current_path

    assert path == "/page_1.html"
  end
end
