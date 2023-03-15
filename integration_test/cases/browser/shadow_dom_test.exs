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
    shadow_root =
      session
      |> find(Query.css("shadow-test"))
      |> shadow_root()

    assert shadow_root
  end

  test "can find stuff within da shadow dom", %{session: session} do
    element =
      session
      |> find(Query.css("shadow-test"))
      |> shadow_root()
      |> find(Query.css("#in-shadow"))
  end

  test "can click stuff within da shadow dom", %{session: session} do
    element =
      session
      |> find(Query.css("shadow-test"))
      |> shadow_root()
      |> click(Query.css("button"))
  end

end
