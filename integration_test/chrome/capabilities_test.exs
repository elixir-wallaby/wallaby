defmodule Wallaby.Integration.CapabilitiesTest do
  use ExUnit.Case, async: false
  use Wallaby.DSL

  import Wallaby.SettingsTestHelpers

  alias Wallaby.Integration.SessionCase
  alias Wallaby.WebdriverClient

  setup do
    ensure_setting_is_reset(:wallaby, :chromedriver)
  end

  describe "capabilities" do
    test "reads default capabilities" do
      assert {:ok, chrome_binary} = Wallaby.Chrome.find_chrome_executable()

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
          binary: chrome_binary,
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
        assert ^expected_capabilities = capabilities

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

    test "reads headless config from application config" do
      headful_capabilities = %{chromeOptions: %{args: []}}

      Application.put_env(:wallaby, :chromedriver,
        capabilities: headful_capabilities,
        headless: true
      )

      create_session_fn = fn _url, capabilities ->
        assert capabilities == %{chromeOptions: %{args: ["--headless"]}}

        {:ok, %{}}
      end

      SessionCase.start_test_session(create_session_fn: create_session_fn)
    end

    test "reads headful config from application config" do
      headless_capabilities = %{chromeOptions: %{args: ["--headless"]}}

      Application.put_env(:wallaby, :chromedriver,
        capabilities: headless_capabilities,
        headless: false
      )

      create_session_fn = fn _url, capabilities ->
        assert capabilities == %{chromeOptions: %{args: []}}

        {:ok, %{}}
      end

      SessionCase.start_test_session(create_session_fn: create_session_fn)
    end

    test "reads chrome binary from application config" do
      capabilities = %{chromeOptions: %{args: [], binary: "wrong/path"}}
      expected_binary_path = "binary/path"

      Application.put_env(:wallaby, :chromedriver,
        capabilities: capabilities,
        binary: expected_binary_path
      )

      create_session_fn = fn _url, capabilities ->
        assert capabilities == %{chromeOptions: %{args: [], binary: expected_binary_path}}

        {:ok, %{}}
      end

      SessionCase.start_test_session(create_session_fn: create_session_fn)
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

    test "adds the beam metadata when it is present" do
      user_agent = "Mozilla/5.0"

      defined_capabilities = %{
        chromeOptions: %{args: ["--headless", "--user-agent=#{user_agent}"]}
      }

      metadata =
        if Version.compare(System.version(), "1.16.0") in [:eq, :gt] do
          "g2gCdwJ2MXQAAAABbQAAAARzb21lbQAAAAhtZXRhZGF0YQ=="
        else
          "g2gCZAACdjF0AAAAAW0AAAAEc29tZW0AAAAIbWV0YWRhdGE="
        end

      expected_capabilities = %{
        chromeOptions: %{
          args: [
            "--headless",
            "--user-agent=#{user_agent}/BeamMetadata (#{metadata})"
          ]
        }
      }

      Application.put_env(:wallaby, :chromedriver, capabilities: defined_capabilities)

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
