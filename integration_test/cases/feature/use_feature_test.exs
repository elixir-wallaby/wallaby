defmodule Wallaby.Integration.Browser.UseFeatureTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  @sessions 2
  feature "multi session", %{sessions: [session_1, session_2]} do
    session_1
    |> visit("/page_1.html")
    |> find(Query.css("body > h1"), fn el ->
      assert Element.text(el) == "Page 1"
    end)

    session_2
    |> visit("/page_2.html")
    |> find(Query.css("body > h1"), fn el ->
      assert Element.text(el) == "Page 2"
    end)
  end

  feature "single session", %{session: only_session} do
    only_session
    |> visit("/page_1.html")
    |> find(Query.css("body > h1"), fn el ->
      assert Element.text(el) == "Page 1"
    end)
  end

  @expected_capabilities Map.put(
                           Wallaby.driver().default_capabilities(),
                           :test,
                           "I'm a capability"
                         )
  @sessions [[capabilities: @expected_capabilities]]
  feature "reads capabilities from session attribute", %{session: %{capabilities: capabilities}} do
    assert capabilities.test == @expected_capabilities.test
  end
end
