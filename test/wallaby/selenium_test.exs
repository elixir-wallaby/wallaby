defmodule Wallaby.SeleniumTest do
  use Wallaby.HttpClientCase, async: true

  alias Wallaby.Selenium
  alias Wallaby.Session
  alias Wallaby.TestSupport.JSONWireProtocolResponses

  describe "start_session/1" do
    test "starts a selenium session with remote_url", %{bypass: bypass} do
      remote_url = bypass_url(bypass, "/")
      session_id = "abc123"

      Bypass.expect(bypass, "POST", "/session", fn conn ->
        response = JSONWireProtocolResponses.start_session_response(session_id: session_id)
        send_json_resp(conn, 200, response)
      end)

      assert {:ok, session} = Selenium.start_session(remote_url: remote_url)

      assert session == %Wallaby.Session{
               session_url: remote_url |> URI.merge("session/#{session_id}") |> to_string(),
               url: remote_url |> URI.merge("session/#{session_id}") |> to_string(),
               id: session_id,
               server: :none,
               capabilities: Wallaby.Selenium.default_capabilities(),
               driver: Wallaby.Selenium
             }
    end

    test "raises a RuntimeError on unknown domain" do
      remote_url = "http://does.not.exist-asdf/"

      assert_raise RuntimeError, ~r/:nxdomain/, fn ->
        Selenium.start_session(remote_url: remote_url)
      end
    end

    test "raises a RuntimeError when unable to connect", %{bypass: bypass} do
      remote_url = bypass_url(bypass, "/")

      Bypass.down(bypass)

      assert_raise RuntimeError, ~r/:econnrefused/, fn ->
        Selenium.start_session(remote_url: remote_url)
      end
    end
  end

  describe "end_session/1" do
    test "returns :ok on success", %{bypass: bypass} do
      %Session{id: session_id} =
        session =
        bypass
        |> bypass_url("/")
        |> build_session()

      Bypass.expect_once(bypass, "DELETE", "/session/#{session_id}", fn conn ->
        response = %{"sessionId" => session_id, "value" => nil, "status" => 0}
        send_json_resp(conn, 200, response)
      end)

      assert :ok = Selenium.end_session(session)
    end

    test "returns :ok when unable to connect", %{bypass: bypass} do
      session =
        bypass
        |> bypass_url("/")
        |> build_session()

      Bypass.down(bypass)

      assert :ok = Selenium.end_session(session)
    end
  end

  defp build_session(remote_url) do
    session_id = random_string(24)
    session_url = remote_url |> URI.merge("session/#{session_id}") |> to_string()

    %Wallaby.Session{
      session_url: session_url,
      url: session_url,
      id: session_id,
      driver: Wallaby.Selenium
    }
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
