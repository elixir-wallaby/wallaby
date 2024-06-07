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

    test "adds the beam metadata when it is present" do
      user_agent = "Mozilla/5.0"

      defined_capabilities = %{
        browserName: "firefox",
        "moz:firefoxOptions": %{
          args: ["-headless"],
          prefs: %{
            "general.useragent.override" => user_agent
          }
        }
      }

      metadata =
        if Version.compare(System.version(), "1.16.0") in [:eq, :gt] do
          "g2gCdwJ2MXQAAAABbQAAAARzb21lbQAAAAhtZXRhZGF0YQ=="
        else
          "g2gCZAACdjF0AAAAAW0AAAAEc29tZW0AAAAIbWV0YWRhdGE="
        end

      expected_capabilities = %{
        browserName: "firefox",
        "moz:firefoxOptions": %{
          args: ["-headless"],
          prefs: %{
            "general.useragent.override" => "#{user_agent}/BeamMetadata (#{metadata})"
          }
        }
      }

      Application.put_env(:wallaby, :selenium, capabilities: defined_capabilities)

      create_session_fn = fn url, capabilities ->
        assert capabilities == expected_capabilities

        WebdriverClient.create_session(url, capabilities)
      end

      {:ok, session} =
        SessionCase.start_test_session(
          create_session_fn: create_session_fn,
          metadata: %{"some" => "metadata"}
        )

      session
      |> visit("page_1.html")
      |> assert_has(Query.text("Page 1"))

      assert :ok = Wallaby.end_session(session)
    end
  end
end
