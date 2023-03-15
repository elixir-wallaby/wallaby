defmodule Wallaby.Integration.Browser.ShadowDomTest do

  use Wallaby.Integration.SessionCase, async: true

  import Wallaby.Query, only: [css: 1]

  setup %{session: session} do
    page =
      session
      |> visit("shadow_dom.html")

    {:ok, page: page}
  end

  test "can find a shadow root", %{session: session} do
    element =
      session
      |> find_shadow(Query.css("shadow-test"))

    assert element
  end
end
