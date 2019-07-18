defmodule Wallaby.Experimental.Selenium.WebdriverClientTest do
  use Wallaby.HttpClientCase, async: true

  alias Wallaby.Experimental.Selenium.WebdriverClient, as: Client
  alias Wallaby.{Element, Query, Session}

  describe "create_session/2" do
    test "sends the correct request to the webdriver backend", %{bypass: bypass} do
      base_url = bypass_url(bypass) <> "/"
      new_session_id = "abc123"
      capabilities = %{
        "platform" => "OS X",
        "browser" => "chrome"
      }

      handle_request bypass, fn conn ->
        assert "POST" == conn.method
        assert "/session" == conn.request_path
        assert %{"desiredCapabilities" => capabilities} == conn.body_params

        send_resp(conn, 200, ~s<{
          "sessionId": "#{new_session_id}",
          "status": 0,
          "value": {
            "acceptSslCerts": false,
            "browserName": "phantomjs"
          }
        }>)
      end

      assert {:ok, response} = Client.create_session(base_url, capabilities)
      assert %{"sessionId" => ^new_session_id} =  response
    end
  end

  describe "delete_session/1" do
    test "sends a delete request to Session.session_url", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      handle_request bypass, fn conn ->
        assert "DELETE" == conn.method
        assert "/session/#{session.id}" == conn.request_path

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": {}
        }>)
      end

      assert {:ok, response} = Client.delete_session(session)
      assert response == %{
        "sessionId" => session.id,
        "status" => 0,
        "value" => %{},
      }
    end
  end

  describe "find_elements/2" do
    test "with a Session as the parent", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element_id = ":wdc:1491326583887"
      query = ".blue" |> Query.css |> Query.compile

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/elements"
        assert conn.body_params == %{"using" => "css selector", "value" => ".blue"}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": [{"ELEMENT": "#{element_id}"}]
        }>)
      end

      assert {:ok, [element]} = Client.find_elements(session, query)
      assert element == %Element{
        id: element_id,
        parent: session,
        session_url: session.url,
        url: "#{session.url}/element/#{element_id}",
        driver: Wallaby.Experimental.Selenium,
      }
    end

    test "with an Element as the parent", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      parent_element = build_element_for_session(session)
      element_id = ":wdc:1491326583887"
      query = ".blue" |> Query.css |> Query.compile

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/element/#{parent_element.id}/elements"
        assert conn.body_params == %{"using" => "css selector", "value" => ".blue"}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": [{"ELEMENT": "#{element_id}"}]
        }>)
      end

      assert {:ok, [element]} = Client.find_elements(parent_element, query)
      assert element == %Element{
        id: element_id,
        parent: parent_element,
        session_url: session.url,
        url: "#{session.url}/element/#{element_id}",
        driver: Wallaby.Experimental.Selenium,
      }
    end

    test "with newer web element identifier", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element_id = ":wdc:1491326583887"
      query = ".blue" |> Query.css |> Query.compile

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/elements"
        assert conn.body_params == %{"using" => "css selector", "value" => ".blue"}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": [{"element-6066-11e4-a52e-4f735466cecf": "#{element_id}"}]
        }>)
      end

      assert {:ok, [element]} = Client.find_elements(session, query)
      assert element == %Element{
        id: element_id,
        parent: session,
        session_url: session.url,
        url: "#{session.url}/element/#{element_id}",
        driver: Wallaby.Experimental.Selenium,
      }
    end
  end

  describe "set_value/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/value"
        assert conn.body_params == %{"value" => [value]}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": null
        }>)
      end

      assert {:ok, nil} = Client.set_value(element, value)
    end

    test "when the server doesn't send a value property", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      handle_request bypass, fn conn ->
        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0
        }>)
      end

      assert {:ok, nil} = Client.set_value(element, value)
    end

    test "correctly handles a 204 response", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      handle_request bypass, fn conn ->
        send_resp(conn, 204, "")
      end

      assert {:ok, nil} = Client.set_value(element, value)
    end

    test "when the server sends back a StaleElementReferenceException", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      handle_request bypass, fn conn ->
        send_resp(conn, 500, ~s<{
          "sessionId": "#{session.id}",
          "status": null,
          "value": {
            "class": "org.openqa.selenium.StaleElementReferenceException"
          }
        }>)
      end

      assert {:error, :stale_reference} = Client.set_value(element, value)
    end
  end

  describe "clear/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/clear"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": null
        }>)
      end

      assert {:ok, nil} = Client.clear(element)
    end

    test "when the server doesn't send a value property", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/clear"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0
        }>)
      end

      assert {:ok, nil} = Client.clear(element)
    end

    test "correctly handles a 204 response", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/clear"

        send_resp(conn, 204, "")
      end

      assert {:ok, nil} = Client.clear(element)
    end

    test "when the server sends back a StaleElementReferenceException", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/clear"

        send_resp(conn, 500, ~s<{
          "sessionId": "#{session.id}",
          "status": null,
          "value": {
            "class": "org.openqa.selenium.StaleElementReferenceException"
          }
        }>)
      end

      assert {:error, :stale_reference} = Client.clear(element)
    end
  end

  describe "click/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/click"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": {}
        }>)
      end

      assert {:ok, %{}} = Client.click(element)
    end
  end

  describe "text/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/text"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": ""
        }>)
      end

      assert {:ok, ""} = Client.text(element)
    end
  end

  describe "page_title/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      page_title = "Wallaby rocks"

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/title"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "#{page_title}"
        }>)
      end

      assert {:ok, ^page_title} = Client.page_title(session)
    end
  end

  describe "attribute/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      attribute_name = "name"

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/attribute/#{attribute_name}"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "password"
        }>)
      end

      assert {:ok, "password"} = Client.attribute(element, "name")
    end
  end

  describe "visit/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com"

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/url"
        assert conn.body_params == %{"url" => url}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": {}
        }>)
      end

      assert :ok = Client.visit(session, url)
    end
  end

  describe "current_url/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com"

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/url"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "#{url}"
        }>)
      end

      assert {:ok, ^url} = Client.current_url(session)
    end
  end

  describe "current_path/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com/search"

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/url"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "#{url}"
        }>)
      end

      assert {:ok, "/search"} = Client.current_path(session)
    end
  end

  describe "selected/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/selected"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": true
        }>)
      end

      assert {:ok, true} = Client.selected(element)
    end
  end

  describe "displayed/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/displayed"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": true
        }>)
      end

      assert {:ok, true} = Client.displayed(element)
    end

    test "with a stale reference exception", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/displayed"

        send_resp(conn, 500, ~s<{
          "sessionId": "#{session.id}",
          "status": 10,
          "value": {
            "class": "org.openqa.selenium.StaleElementReferenceException"
          }
        }>)
      end

      assert {:error, :stale_reference} = Client.displayed(element)
    end
  end

  describe "size/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/size"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "not quite sure"
        }>)
      end

      assert {:ok, "not quite sure"} = Client.size(element)
    end
  end

  describe "rect/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/rect"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "not quite sure"
        }>)
      end

      assert {:ok, "not quite sure"} = Client.rect(element)
    end
  end

  describe "take_screenshot/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      screenshot_data = ":)"

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/screenshot"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "#{Base.encode64(screenshot_data)}"
        }>)
      end

      assert ^screenshot_data = Client.take_screenshot(session)
    end
  end

  describe "cookies/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/cookie"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": [{"domain": "localhost"}]
        }>)
      end

      assert {:ok, [%{"domain" => "localhost"}]} = Client.cookies(session)
    end
  end

  describe "set_cookie/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      key = "tester"
      value = "McTestington"

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/cookie"
        assert conn.body_params == %{"cookie" => %{"name" => key, "value" => value}}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": []
        }>)
      end

      assert {:ok, []} = Client.set_cookie(session, key, value)
    end
  end

  describe "set_window_size/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      window_handle_id = "my-window-handle"
      height = 600
      width = 400

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/window/#{window_handle_id}/size"
        assert conn.body_params == %{"height" => height, "width" => width}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": {}
        }>)
      end

      assert {:ok, %{}} = Client.set_window_size(session, window_handle_id, width, height)
    end
  end

  describe "get_window_size/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      window_handle_id = "my-window-handle"

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/window/#{window_handle_id}/size"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": {
            "height": 600,
            "width": 400
          }
        }>)
      end

      assert {:ok, %{"height" => 600, "width" => 400}} == Client.get_window_size(session, window_handle_id)
    end
  end

  describe "execute_script/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/execute"
        assert conn.body_params == %{
        "script" => "localStorage.clear()",
        "args" => [2, "a"]}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": null
        }>)
      end

      assert {:ok, nil} = Client.execute_script(session, "localStorage.clear()", [2, "a"])
    end
  end

  describe "send_keys/2" do
    test "with a Session", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      keys = ["abc", :tab]

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/keys"
        assert conn.body_params == Wallaby.Helpers.KeyCodes.json(keys) |> Poison.decode!

        resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": null
        }>)
      end

      assert {:ok, nil} = Client.send_keys(session, keys)
    end

    test "with an Element", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      keys = ["abc", :tab]

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/element/#{element.id}/value"
        assert conn.body_params == Wallaby.Helpers.KeyCodes.json(keys) |> Poison.decode!

        resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": null
        }>)
      end

      assert {:ok, nil} = Client.send_keys(element, keys)
    end
  end

  describe "log/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/log"
        assert conn.body_params == %{"type" => "browser"}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": []
        }>)
      end

      assert {:ok, []} = Client.log(session)
    end
  end

  describe "page_source/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      page_source = "<html></html>"

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/source"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "#{page_source}"
        }>)
      end

      assert {:ok, ^page_source} = Client.page_source(session)
    end
  end

  describe "window_handle/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      handle_request bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/session/#{session.id}/window_handle"

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "my-window-handle"
        }>)
      end

      assert "my-window-handle" = Client.window_handle(session)
    end
  end

  describe "hover/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      handle_request bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/moveto"
        assert conn.body_params == %{"element" => element.id}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": {}
        }>)
      end

      assert {:ok, %{}} = Client.hover(element)
    end
  end

  defp handle_request(bypass, handler_fn) do
    Bypass.expect bypass, fn conn ->
      conn |> parse_body |> handler_fn.()
    end
  end

  defp build_session_for_bypass(bypass, session_id \\ "my-sample-session") do
    session_url = bypass_url(bypass, "/session/#{session_id}")

    %Session{driver: Wallaby.Experimental.Selenium, id: session_id, session_url: session_url, url: session_url}
  end

  defp build_element_for_session(session, element_id \\ ":wdc:abc123") do
    %Element{
      driver: Wallaby.Experimental.Selenium,
      id: element_id,
      parent: session,
      session_url: session.url,
      url: "#{session.url}/element/#{element_id}",
    }
  end
end
