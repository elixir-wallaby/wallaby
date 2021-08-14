defmodule Wallaby.Integration.Browser.CustomElementTest do
  use Wallaby.Integration.SessionCase, async: true


  test "get an element in the shadow DOM",  %{session: session} do
    session |> visit("custom_element.html") |> within_shadow_dom("my-element", fn shadow_dom ->
      IO.inspect(shadow_dom)
      shadow_dom |> assert_has(Query.css("#find_me"))
    end)
  end

end
