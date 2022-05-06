defmodule Wallaby.Integration.SeleniumCapabilitiesTest do
  use ExUnit.Case, async: false
  use Wallaby.DSL

  import Wallaby.SettingsTestHelpers

  alias Wallaby.Integration.SessionCase
  alias Wallaby.WebdriverClient

  setup do
    ensure_setting_is_reset(:wallaby, :selenium)
  end

  describe "capabilities" do
    test "reads default capabilities" do
      expected_capabilities = %{
        browserName: "firefox",
        "moz:firefoxOptions": %{
          args: ["-headless"],
          prefs: %{
            "general.useragent.override" =>
              "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
          }
        }
      }

      create_session_fn = fn url, capabilities ->
        assert capabilities == expected_capabilities

        WebdriverClient.create_session(url, capabilities)
      end

      {:ok, session} = SessionCase.start_test_session(create_session_fn: create_session_fn)

      session
      |> visit("page_1.html")
      |> assert_has(Query.text("Page 1"))

      assert :ok = Wallaby.end_session(session)
    end

    test "reads capabilities from application config" do
      expected_capabilities = %{
        browserName: "firefox",
        "moz:firefoxOptions": %{
          args: ["-headless"]
        }
      }

      Application.put_env(:wallaby, :selenium, capabilities: expected_capabilities)

      create_session_fn = fn url, capabilities ->
        assert capabilities == expected_capabilities

        WebdriverClient.create_session(url, capabilities)
      end

      {:ok, session} = SessionCase.start_test_session(create_session_fn: create_session_fn)

      session
      |> visit("page_1.html")
      |> assert_has(Query.text("Page 1"))

      assert :ok = Wallaby.end_session(session)
    end
  end
end
