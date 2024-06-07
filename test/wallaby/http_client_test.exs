defmodule Wallaby.HTTPClientTest do
  use Wallaby.HttpClientCase, async: true

  alias Wallaby.HTTPClient, as: Client

  describe "request/4" do
    test "sends the request with the correct params and headers", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        conn = parse_body(conn)
        assert conn.method == "POST"
        assert conn.request_path == "/my_url"
        assert conn.body_params == %{"hello" => "world"}
        assert get_req_header(conn, "accept") == ["application/json"]
        assert get_req_header(conn, "content-type") == ["application/json;charset=UTF-8"]

        send_json_resp(conn, 200, %{
          "sessionId" => "abc123",
          "status" => 0,
          "value" => nil
        })
      end)

      assert {:ok, _} = Client.request(:post, bypass_url(bypass, "/my_url"), %{hello: "world"})
    end

    test "with a 200 status response", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => "abc123",
          "status" => 0,
          "value" => nil
        })
      end)

      {:ok, response} = Client.request(:post, bypass_url(bypass, "/my_url"))

      assert response == %{
               "sessionId" => "abc123",
               "status" => 0,
               "value" => nil
             }
    end

    test "with a 500 response and StaleElementReferenceException", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        send_json_resp(conn, 500, %{
          "sessionId" => "abc123",
          "status" => 10,
          "value" => %{
            "class" => "org.openqa.selenium.StaleElementReferenceException"
          }
        })
      end)

      assert {:error, :stale_reference} = Client.request(:post, bypass_url(bypass, "/my_url"))
    end

    test "with an obscure status code", %{bypass: bypass} do
      expected_message = "message from an obscure error"

      Bypass.expect(bypass, fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => "abc123",
          "status" => 13,
          "value" => %{
            "message" => "#{expected_message}"
          }
        })
      end)

      assert {:error, ^expected_message} = Client.request(:post, bypass_url(bypass, "/my_url"))
    end

    test "includes the original HTTPoison error when there is one", %{bypass: bypass} do
      expected_message =
        if Version.compare(System.version(), "1.16.0") in [:eq, :gt] do
          "Wallaby had an internal issue with HTTPoison:\n%HTTPoison.Error{reason: :econnrefused, id: nil}"
        else
          "Wallaby had an internal issue with HTTPoison:\n%HTTPoison.Error{id: nil, reason: :econnrefused}"
        end

      Bypass.down(bypass)

      assert_raise RuntimeError, expected_message, fn ->
        Client.request(:post, bypass_url(bypass, "/my_url"))
      end
    end

    test "raises a runtime error when the request returns a generic error", %{bypass: bypass} do
      expected_message = "The session could not be created"

      Bypass.expect(bypass, fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => "abc123",
          "value" => %{
            "error" => "An error",
            "message" => "#{expected_message}"
          }
        })
      end)

      assert_raise RuntimeError, expected_message, fn ->
        Client.request(:post, bypass_url(bypass, "/my_url"))
      end
    end
  end
end
