defmodule Wallaby.Phantom.Webdriver.ClientTest do
  use Wallaby.HttpClientCase, async: true

  alias Wallaby.Phantom.Webdriver.Client
  alias Wallaby.Session


  describe "execute_script/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/phantom/execute"
        assert conn.body_params == %{
        "script" => "localStorage.clear()",
        "args" => [2, "a"]}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": ["ok", null]
        }>)
      end

      assert {:ok, ["ok", nil]} = Client.execute_script(session, "localStorage.clear()", [2, "a"])
    end
  end

  defp handle_request(bypass, handler_fn) do
    Bypass.expect bypass, fn conn ->
      conn |> parse_body |> handler_fn.()
    end
  end

  defp build_session_for_bypass(bypass, session_id \\ "my-sample-session") do
    session_url = bypass_url(bypass, "/session/#{session_id}")

    %Session{id: session_id, session_url: session_url, url: session_url}
  end
end
