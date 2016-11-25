defmodule Wallaby.Browser.NavigationTest do
  use Wallaby.SessionCase, async: false

  test "navigating by path only", %{session: session} do
    visit(session, "page_1.html")

    element =
      session
      |> find(".blue")

    assert element
  end

  test "visit/2 with a relative url and no base url raises exception", %{session: session} do
    original_url = Application.get_env(:wallaby, :base_url)

    assert_raise(Wallaby.NoBaseUrl, fn ->
      Application.put_env(:wallaby, :base_url, nil)
      session
      |> visit("/page_1.html")
    end)

    Application.put_env(:wallaby, :base_url, original_url)
  end

  test "visit/2 with an absolute path does not use the base url", %{session: session} do
    session
    |> visit("/page_1.html")

    assert has_css?(session, "#visible")
  end
end
