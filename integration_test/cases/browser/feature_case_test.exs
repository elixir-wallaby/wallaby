defmodule Wallaby.Integration.Browser.FeatureCaseTest do
  use Wallaby.FeatureCase, async: true

  alias Wallaby.Integration.Browser.FeatureCaseTest
  alias Wallaby.Experimental.Selenium.WebdriverClient

  def create_session_fn(url, capabilities) do
    assert capabilities == %{test: "I'm a capability"}

    WebdriverClient.create_session(
      url,
      Wallaby.driver().default_capabilities()
    )
  end

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

  feature "single session", %{sessions: [only_session]} do
    only_session
    |> visit("/page_1.html")
    |> find(Query.css("body > h1"), fn el ->
      assert Element.text(el) == "Page 1"
    end)
  end

  @sessions [
    [
      create_session_fn: &FeatureCaseTest.create_session_fn/2,
      capabilities: %{
        test: "I'm a capability"
      }
    ]
  ]
  feature "reads capabilities from session attribute", %{sessions: session} do
    assert true
  end
end
