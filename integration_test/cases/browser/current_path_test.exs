defmodule Wallaby.Integration.Browser.CurrentPathTest do
  use Wallaby.Integration.SessionCase, async: true

  alias Wallaby.Integration.Pages.{IndexPage, Page1}

  test "gets the current_url of the session", %{session: session} do
    url =
      session
      |> IndexPage.visit()
      |> IndexPage.click_page_1_link()
      |> Page1.ensure_page_loaded()
      |> current_url()

    assert url == "http://localhost:#{URI.parse(url).port}/page_1.html"
  end

  test "gets the current_path of the session", %{session: session} do
    path =
      session
      |> IndexPage.visit()
      |> IndexPage.click_page_1_link()
      |> Page1.ensure_page_loaded()
      |> current_path()

    assert path == "/page_1.html"
  end
end
