defmodule Wallaby.Integration.Browser.UseFeatureTestTest do
  use ExUnit.Case, async: true
  use Wallaby.FeatureTest

  alias Wallaby.Integration.Browser.UseFeatureTestTest
  alias Wallaby.Experimental.Selenium.WebdriverClient

  setup do
    Wallaby.SettingsTestHelpers.ensure_setting_is_reset(:wallaby, :screenshot_on_failure)
    Application.put_env(:wallaby, :screenshot_on_failure, true)

    :ok
  end

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
      create_session_fn: &UseFeatureTestTest.create_session_fn/2,
      capabilities: %{
        test: "I'm a capability"
      }
    ]
  ]
  feature "reads capabilities from session attribute" do
    assert true
  end
end
