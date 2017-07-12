defmodule Wallaby.HTTPClientTest do
  use Wallaby.HttpClientCase, async: true

  alias Wallaby.HTTPClient, as: Client

  describe "request/4" do
    test "sends the request with the correct params and headers", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        conn = parse_body(conn)
        assert conn.method == "POST"
        assert conn.request_path == "/my_url"
        assert conn.body_params == %{"hello" => "world"}
        assert get_req_header(conn, "accept") == ["application/json"]
        assert get_req_header(conn, "content-type") == ["application/json"]

        send_resp(conn, 200, ~s<{
          "sessionId": "abc123",
          "status": 0,
          "value": null
        }>)
      end

      assert {:ok, _} = Client.request(:post, bypass_url(bypass, "/my_url"), %{hello: "world"})
    end

    test "with a 200 status response", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        send_resp(conn, 200, ~s<{
          "sessionId": "abc123",
          "status": 0,
          "value": null
        }>)
      end

      {:ok, response} = Client.request(:post, bypass_url(bypass, "/my_url"))
      assert response == %{
        "sessionId" => "abc123",
        "status" => 0,
        "value" => nil
      }
    end

    test "with a 500 response and StaleElementReferenceException", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        send_resp(conn, 500, ~s<{
          "sessionId": "abc123",
          "status": 10,
          "value": {
            "class": "org.openqa.selenium.StaleElementReferenceException"
          }
        }>)
      end

      assert {:error, :stale_reference} =
        Client.request(:post, bypass_url(bypass, "/my_url"))
    end
  end
end
