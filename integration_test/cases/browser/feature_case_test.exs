defmodule Wallaby.Integration.Browser.FeatureCaseTest do
  use Wallaby.FeatureCase, async: true

  Application.put_env(
    :wallaby,
    :capabilities,
    case(System.get_env("WALLABY_DRIVER")) do
      "selenium" ->
        %{
          browserName: "firefox",
          "moz:firefoxOptions": %{
            args: ["-headless"]
          }
        }

      _ ->
        Map.new()
    end
  )

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
end
