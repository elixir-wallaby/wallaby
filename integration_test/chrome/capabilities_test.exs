defmodule Wallaby.Integration.CapabilitiesTest do
  use ExUnit.Case
  use Wallaby.DSL
  alias Wallaby.Integration.SessionCase
  alias Wallaby.Experimental.Selenium.WebdriverClient

  setup do
    on_exit fn ->
      Application.delete_env(:wallaby, :chromedriver)
    end
  end

  describe "capabilities" do
    test "reads default capabilities" do
      expected_capabilities = %{
        javascriptEnabled: false,
        loadImages: false,
        version: "",
        rotatable: false,
        takesScreenshot: true,
        cssSelectorsEnabled: true,
        nativeEvents: false,
        platform: "ANY",
        unhandledPromptBehavior: "accept",
        loggingPrefs: %{
          browser: "DEBUG"
        },
        chromeOptions: %{
          args: [
            "--no-sandbox",
            "window-size=1280,800",
            "--disable-gpu",
            "--headless",
            "--fullscreen",
            "--user-agent=Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
          ]
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
      expected_capabilities = %{chromeOptions: %{args: ["--headless"]}}
      Application.put_env(:wallaby, :chromedriver, capabilities: expected_capabilities)

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
      Application.put_env(:wallaby, :chromedriver, capabilities: %{})
      expected_capabilities = %{chromeOptions: %{args: ["--headless"]}}

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
