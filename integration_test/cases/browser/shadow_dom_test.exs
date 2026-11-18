defmodule Wallaby.Integration.Browser.ShadowDomTest do
  use Wallaby.Integration.SessionCase, async: true

  alias Wallaby.Element

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

    assert %Element{} = shadow_root
  end

  test "can find elements within a shadow dom", %{session: session} do
    element =
      session
      |> find(Query.css("shadow-test"))
      |> shadow_root()
      |> find(Query.css("#in-shadow"))

    assert Element.text(%Element{} = element) == "I am in shadow"
  end

  test "can click elements within a shadow dom", %{session: session} do
    element =
      session
      |> find(Query.css("shadow-test"))
      |> shadow_root()
      |> click(Query.css("#option1"))
      |> click(Query.css("#option2"))

    assert selected?(element, Query.css("#option2"))
  end

  test "does not return a shadow root when one does not exist", %{session: session} do
    shadow_root =
      session
      |> find(Query.css("#outside-shadow"))
      |> shadow_root()

    refute shadow_root
  end
end
