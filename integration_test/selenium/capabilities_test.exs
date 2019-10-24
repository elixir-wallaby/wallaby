defmodule Wallaby.Integration.Selenium.CapabilitiesTest do
  use ExUnit.Case
  use Wallaby.DSL
  alias Wallaby.Integration.SessionCase
  alias Wallaby.Experimental.Selenium.WebdriverClient

  setup do
    on_exit(fn ->
      Application.delete_env(:wallaby, :selenium)
    end)
  end

  describe "capabilities" do
    test "reads default capabilities" do
      expected_capabilities = %{
        javascriptEnabled: true,
        browserName: "firefox",
        "moz:firefoxOptions": %{
          args: ["-headless"]
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

    test "reads capabilities from opts when also using application config" do
      Application.put_env(:wallaby, :selenium, capabilities: %{})

      expected_capabilities = %{
        browserName: "firefox",
        "moz:firefoxOptions": %{
          args: ["-headless"]
        }
      }

      create_session_fn = fn url, capabilities ->
        assert capabilities == expected_capabilities

        WebdriverClient.create_session(url, capabilities)
      end

      {:ok, session} =
        SessionCase.start_test_session(
          capabilities: expected_capabilities,
          create_session_fn: create_session_fn
        )

      session
      |> visit("page_1.html")
      |> assert_has(Query.text("Page 1"))

      assert :ok = Wallaby.end_session(session)
    end
  end
end
