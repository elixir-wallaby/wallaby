defmodule Wallaby.Integration.Browser.ImportFeatureTestTest do
  use Wallaby.Integration.SessionCase, async: true
  import Wallaby.FeatureTest

  setup do
    Wallaby.SettingsTestHelpers.ensure_setting_is_reset(:wallaby, :screenshot_on_failure)
    Application.put_env(:wallaby, :screenshot_on_failure, true)

    :ok
  end

  feature "works", %{session: session} do
    session
    |> visit("/page_1.html")
    |> find(Query.css("body > h1"), fn el ->
      assert Element.text(el) == "Page 1"
    end)
  end
end
