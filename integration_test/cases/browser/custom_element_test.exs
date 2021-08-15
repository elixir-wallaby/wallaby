defmodule Wallaby.Integration.Browser.CustomElementTest do
  use Wallaby.Integration.SessionCase, async: true

  test "get an element in the shadow DOM", %{session: session} do
    session
    |> visit("custom_element.html")
    |> within_shadow_dom("my-element", fn shadow_dom ->
      shadow_dom |> assert_has(Query.css("#find_me"))
    end)
  end

  test "interact with custom element that throws custom event", %{session: session} do
    session
    |> visit("custom_element.html")
    |> within_shadow_dom("custom-event-throwing", fn shadow_dom ->
      shadow_dom |> click(Query.css("#click_me"))
    end)
    |> assert_has(Query.css("#foo", text: "bar"))
  end
end
