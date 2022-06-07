defmodule Wallaby.Selenium.StartSessionConfigTest do
  use Wallaby.HttpClientCase, async: false

  # These tests modify the application environment so need
  # to be run with async: false

  alias Wallaby.Selenium
  alias Wallaby.Session
  alias Wallaby.SettingsTestHelpers
  alias Wallaby.TestSupport.JSONWireProtocolResponses

  setup do
    SettingsTestHelpers.ensure_setting_is_reset(:wallaby, :selenium)
  end

  test "starting a session uses default capabilities when none is set", %{bypass: bypass} do
    remote_url = bypass_url(bypass, "/")
    Application.delete_env(:wallaby, :selenium)

    Bypass.expect(bypass, "POST", "/session", fn conn ->
      conn = parse_body(conn)

      assert conn.body_params == %{
               "desiredCapabilities" => %{
                 "browserName" => "firefox",
                 "moz:firefoxOptions" => %{
                   "args" => ["-headless"],
                   "prefs" => %{
                     "general.useragent.override" =>
                       "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
                   }
                 }
               }
             }

      response = JSONWireProtocolResponses.start_session_response()
      send_json_resp(conn, 200, response)
    end)

    assert {:ok, %Session{}} = Selenium.start_session(remote_url: remote_url)
  end

  test "starting a session reads capabilities from app env when set", %{bypass: bypass} do
    remote_url = bypass_url(bypass, "/")

    configured_capabilities = %{
      browserName: "firefox",
      "moz:firefoxOptions": %{
        args: ["-headless"]
      }
    }

    Application.put_env(:wallaby, :selenium, capabilities: configured_capabilities)

    Bypass.expect(bypass, "POST", "/session", fn conn ->
      conn = parse_body(conn)

      assert conn.body_params == %{
               "desiredCapabilities" => %{
                 "browserName" => "firefox",
                 "moz:firefoxOptions" => %{"args" => ["-headless"]}
               }
             }

      response = JSONWireProtocolResponses.start_session_response()
      send_json_resp(conn, 200, response)
    end)

    assert {:ok, %Session{}} = Selenium.start_session(remote_url: remote_url)
  end

  test "starting a session reads capabilities from opts and app env when set", %{bypass: bypass} do
    remote_url = bypass_url(bypass, "/")

    Application.put_env(:wallaby, :selenium, capabilities: %{})

    capabilities_opt = %{
      browserName: "firefox",
      "moz:firefoxOptions": %{
        args: ["-headless"]
      }
    }

    Bypass.expect(bypass, "POST", "/session", fn conn ->
      conn = parse_body(conn)

      assert conn.body_params == %{
               "desiredCapabilities" => %{
                 "browserName" => "firefox",
                 "moz:firefoxOptions" => %{"args" => ["-headless"]}
               }
             }

      response = JSONWireProtocolResponses.start_session_response()
      send_json_resp(conn, 200, response)
    end)

    assert {:ok, %Session{}} =
             Selenium.start_session(remote_url: remote_url, capabilities: capabilities_opt)
  end
end
