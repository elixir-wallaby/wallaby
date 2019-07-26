defmodule Wallaby.Phantom.DriverTest do
  use Wallaby.HttpClientCase, async: true

  alias Wallaby.{Element, Phantom, Query, Session, StaleReferenceError}
  alias Wallaby.Phantom.Driver

  @window_handle_id "bdc333b0-1989-11e7-a2c3-d1d2d92b0e58"

  describe "create_session/2" do
    test "sends the correct request to the webdriver backend", %{bypass: bypass} do
      base_url = bypass_url(bypass) <> "/"
      new_session_id = "abc123"
      capabilities = %{
        "platform" => "OS X",
        "browser" => "chrome"
      }

      Bypass.expect bypass, fn conn ->
        conn = parse_body(conn)
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

      assert {:ok, response} = Driver.create_session(base_url, capabilities)
      assert %{"sessionId" => ^new_session_id} =  response
    end
  end

  describe "delete/1" do
    test "sends a delete request to Session.session_url", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      Bypass.expect bypass, fn conn ->
        assert "DELETE" == conn.method
        assert "/session/#{session.id}" == conn.request_path

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": {}
        }>)
      end

      assert {:ok, response} = Driver.delete(session)
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

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" && conn.request_path == "/session/#{session.id}/elements" do
          assert conn.body_params == %{"using" => "css selector", "value" => ".blue"}

          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": [{"ELEMENT": "#{element_id}"}]
          }>)
        end
      end

      assert {:ok, [element]} = Driver.find_elements(session, query)
      assert element == %Element{
        driver: Phantom,
        id: element_id,
        parent: session,
        session_url: session.url,
        url: "#{session.url}/element/#{element_id}",
      }
    end

    test "with an Element as the parent", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      parent_element = build_element_for_session(session)
      element_id = ":wdc:1491326583887"
      query = ".blue" |> Query.css |> Query.compile

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" &&
          conn.request_path == "/session/#{session.id}/element/#{parent_element.id}/elements" do
          assert conn.body_params == %{"using" => "css selector", "value" => ".blue"}

          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": [{"ELEMENT": "#{element_id}"}]
          }>)
        end
      end

      assert {:ok, [element]} = Driver.find_elements(parent_element, query)
      assert element == %Element{
        driver: Phantom,
        id: element_id,
        parent: parent_element,
        session_url: session.url,
        url: "#{session.url}/element/#{element_id}",
      }
    end
  end

  describe "set_value/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/value" do

          assert conn.body_params == %{"value" => [value]}

          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": null
          }>)
        end
      end

      assert {:ok, nil} = Driver.set_value(element, value)
    end
  end

  describe "clear/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/clear" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": null
          }>)
        end
      end

      assert {:ok, nil} = Driver.clear(element)
    end
  end

  describe "click/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/click" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": {}
          }>)
        end
      end

      assert {:ok, %{}} = Driver.click(element)
    end
  end

  describe "text/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/text" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": ""
          }>)
        end
      end

      assert {:ok, ""} = Driver.text(element)
    end
  end

  describe "page_title/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      page_title = "Wallaby rocks"

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" && conn.request_path == "/session/#{session.id}/title" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": "#{page_title}"
          }>)
        end
      end

      assert {:ok, ^page_title} = Driver.page_title(session)
    end
  end

  describe "attribute/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      attribute_name = "name"

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/attribute/#{attribute_name}" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": "password"
          }>)
        end
      end

      assert {:ok, "password"} = Driver.attribute(element, "name")
    end
  end

  describe "visit/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com"

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" && conn.request_path == "/session/#{session.id}/url" do
          assert conn.body_params == %{"url" => url}

          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": {}
          }>)
        end
      end

      assert :ok = Driver.visit(session, url)
    end

    test "when browser sends back a 204 response", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com"

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" && conn.request_path == "/session/#{session.id}/url" do
          assert conn.body_params == %{"url" => url}

          send_resp(conn, 204, "")
        end
      end

      assert :ok = Driver.visit(session, url)
    end
  end

  describe "current_url/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com"

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" && conn.request_path == "/session/#{session.id}/url" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": "#{url}"
          }>)
        end
      end

      assert {:ok, ^url} = Driver.current_url(session)
    end
  end

  describe "current_path/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com/search"

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" && conn.request_path == "/session/#{session.id}/url" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": "#{url}"
          }>)
        end
      end

      assert {:ok, "/search"} = Driver.current_path(session)
    end
  end

  describe "selected/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/selected" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": true
          }>)
        end
      end

      assert {:ok, true} = Driver.selected(element)
    end
  end

  describe "displayed/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/displayed" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": true
          }>)
        end
      end

      assert {:ok, true} = Driver.displayed(element)
    end

    test "with a stale reference exception", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/displayed" do
          send_resp(conn, 500, ~s<{
            "sessionId": "#{session.id}",
            "status": 10,
            "value": {
              "class": "org.openqa.selenium.StaleElementReferenceException"
            }
          }>)
        end
      end

      assert {:error, :stale_reference} = Driver.displayed(element)
    end
  end

  describe "displayed!/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/displayed" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": true
          }>)
        end
      end

      assert true = Driver.displayed!(element)
    end

    test "with a stale reference exception", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/displayed" do
          send_resp(conn, 500, ~s<{
            "sessionId": "#{session.id}",
            "status": 10,
            "value": {
              "class": "org.openqa.selenium.StaleElementReferenceException"
            }
          }>)
        end
      end

      assert_raise StaleReferenceError, fn ->
        Driver.displayed!(element)
      end
    end
  end

  describe "size/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/size" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": "not quite sure"
          }>)
        end
      end

      assert {:ok, "not quite sure"} = Driver.size(element)
    end
  end

  describe "rect/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/rect" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": "not quite sure"
          }>)
        end
      end

      assert {:ok, "not quite sure"} = Driver.rect(element)
    end
  end

  describe "take_screenshot/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      screenshot_data = ":)"

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" && conn.request_path == "/session/#{session.id}/screenshot" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": "#{Base.encode64(screenshot_data)}"
          }>)
        end
      end

      assert ^screenshot_data = Driver.take_screenshot(session)
    end
  end

  describe "cookies/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" && conn.request_path == "/session/#{session.id}/cookie" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": [{"domain": "localhost"}]
          }>)
        end
      end

      assert {:ok, [%{"domain" => "localhost"}]} = Driver.cookies(session)
    end
  end

  describe "set_cookie/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      key = "tester"
      value = "McTestington"

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" && conn.request_path == "/session/#{session.id}/cookie" do
          assert conn.body_params == %{"cookie" => %{"name" => key, "value" => value}}

          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": []
          }>)
        end
      end

      assert {:ok, []} = Driver.set_cookie(session, key, value)
    end
  end

  describe "set_window_size/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      height = 600
      width = 400

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" &&
          conn.request_path == "/session/#{session.id}/window/#{@window_handle_id}/size" do
          assert conn.body_params == %{"height" => height, "width" => width}

          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": {}
          }>)
        end
      end

      assert {:ok, %{}} = Driver.set_window_size(session, width, height)
    end
  end

  describe "get_window_size/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" &&
          conn.request_path == "/session/#{session.id}/window/#{@window_handle_id}/size" do

          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": {
              "height": 600,
              "width": 400
            }
          }>)
        end
      end

      assert {:ok, %{}} = Driver.get_window_size(session)
    end
  end

  describe "execute_script/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" &&
          conn.request_path == "/session/#{session.id}/execute" do
          assert conn.body_params == %{
          "script" => "localStorage.clear()",
          "args" => [2, "a"]}


          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": null
          }>)
        end
      end

      assert {:ok, nil} = Driver.execute_script(session, "localStorage.clear()", [2, "a"])
    end
  end

  describe "send_keys/2" do
    test "with a Session", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      keys = ["abc", :tab]

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" && conn.request_path == "/session/#{session.id}/keys" do
          assert conn.body_params == Wallaby.Helpers.KeyCodes.json(keys) |> Jason.decode!

          resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": null
          }>)
        end
      end

      assert {:ok, nil} = Driver.send_keys(session, keys)
    end

    test "with an Element", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      keys = ["abc", :tab]

      stub_backend bypass, session, fn conn ->
        if conn.method == "POST" &&
          conn.request_path == "/session/#{session.id}/element/#{element.id}/value" do
          assert conn.body_params == Wallaby.Helpers.KeyCodes.json(keys) |> Jason.decode!

          resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": null
          }>)
        end
      end

      assert {:ok, nil} = Driver.send_keys(element, keys)
    end
  end

  describe "log/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      Bypass.expect bypass, fn conn ->
        conn = parse_body(conn)
        assert conn.method == "POST"
        assert conn.request_path == "/session/#{session.id}/log"
        assert conn.body_params == %{"type" => "browser"}

        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": []
        }>)
      end

      assert {:ok, []} = Driver.log(session)
    end
  end

  describe "page_source/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      page_source = "<html></html>"

      stub_backend bypass, session, fn conn ->
        if conn.method == "GET" && conn.request_path == "/session/#{session.id}/source" do
          send_resp(conn, 200, ~s<{
            "sessionId": "#{session.id}",
            "status": 0,
            "value": "#{page_source}"
          }>)
        end
      end

      assert {:ok, ^page_source} = Driver.page_source(session)
    end
  end

  defp build_session_for_bypass(bypass, session_id \\ "my-sample-session") do
    session_url = bypass_url(bypass, "/session/#{session_id}")

    %Session{driver: Phantom, id: session_id, session_url: session_url, url: session_url}
  end

  defp build_element_for_session(session, element_id \\ ":wdc:abc123") do
    %Element{
      driver: Phantom,
      id: element_id,
      parent: session,
      session_url: session.url,
      url: "#{session.url}/element/#{element_id}",
    }
  end

  # Sets up bypass to run the given function and if no result is set, runs the
  # default routes.
  defp stub_backend(bypass, session, handle_fn) do
    Bypass.expect bypass, fn conn ->
      conn = parse_body(conn)

      case handle_fn.(conn) do
        %Plug.Conn{state: :set} = conn -> conn
        %Plug.Conn{state: :sent} = conn -> conn
        _ -> handle_default_routes(conn, session)
      end
    end
  end

  defp handle_default_routes(conn, session) do
    cond do
      conn.method == "POST" && conn.request_path == "/session/#{session.id}/log" ->
        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": []
        }>)
      conn.method == "GET" && conn.request_path == "/session/#{session.id}/window_handle" ->
        send_resp(conn, 200, ~s<{
          "sessionId": "#{session.id}",
          "status": 0,
          "value": "#{@window_handle_id}"
        }>)
      true ->
        refute true, "Unhandled request #{conn.method} #{conn.request_path}"
    end
  end
end
