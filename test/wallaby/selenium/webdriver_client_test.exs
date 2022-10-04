defmodule Wallaby.WebdriverClientTest do
  use Wallaby.HttpClientCase, async: true

  alias Wallaby.WebdriverClient, as: Client
  alias Wallaby.{Element, Query, Session}

  @web_element_identifier "element-6066-11e4-a52e-4f735466cecf"

  describe "create_session/2" do
    test "sends the correct request to the webdriver backend", %{bypass: bypass} do
      base_url = bypass_url(bypass) <> "/"
      new_session_id = "abc123"

      capabilities = %{
        "platform" => "OS X",
        "browser" => "chrome"
      }

      Bypass.expect(bypass, "POST", "/session", fn conn ->
        conn = parse_body(conn)
        assert %{"desiredCapabilities" => capabilities} == conn.body_params

        send_json_resp(conn, 200, %{
          "sessionId" => "#{new_session_id}",
          "status" => 0,
          "value" => %{
            "acceptSslCerts" => false,
            "browserName" => "chrome"
          }
        })
      end)

      assert {:ok, response} = Client.create_session(base_url, capabilities)
      assert %{"sessionId" => ^new_session_id} = response
    end
  end

  describe "delete_session/1" do
    test "sends a delete request to Session.session_url", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "DELETE", "/session/#{session.id}", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, response} = Client.delete_session(session)

      assert response == %{
               "sessionId" => session.id,
               "status" => 0,
               "value" => %{}
             }
    end
  end

  describe "find_elements/2" do
    test "with a Session as the parent", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element_id = ":wdc:1491326583887"
      query = ".blue" |> Query.css() |> Query.compile()

      Bypass.expect(bypass, "POST", "/session/#{session.id}/elements", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"using" => "css selector", "value" => ".blue"}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => [%{"ELEMENT" => "#{element_id}"}]
        })
      end)

      assert {:ok, [element]} = Client.find_elements(session, query)

      assert element == %Element{
               id: element_id,
               parent: session,
               session_url: session.url,
               url: "#{session.url}/element/#{element_id}",
               driver: Wallaby.Selenium
             }
    end

    test "with an Element as the parent", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      parent_element = build_element_for_session(session)
      element_id = ":wdc:1491326583887"
      query = ".blue" |> Query.css() |> Query.compile()

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{parent_element.id}/elements",
        fn conn ->
          conn = parse_body(conn)
          assert conn.body_params == %{"using" => "css selector", "value" => ".blue"}

          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => [%{"ELEMENT" => "#{element_id}"}]
          })
        end
      )

      assert {:ok, [element]} = Client.find_elements(parent_element, query)

      assert element == %Element{
               id: element_id,
               parent: parent_element,
               session_url: session.url,
               url: "#{session.url}/element/#{element_id}",
               driver: Wallaby.Selenium
             }
    end

    test "with newer web element identifier", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element_id = ":wdc:1491326583887"
      query = ".blue" |> Query.css() |> Query.compile()

      Bypass.expect(bypass, "POST", "/session/#{session.id}/elements", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"using" => "css selector", "value" => ".blue"}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => [%{"#{@web_element_identifier}" => "#{element_id}"}]
        })
      end)

      assert {:ok, [element]} = Client.find_elements(session, query)

      assert element == %Element{
               id: element_id,
               parent: session,
               session_url: session.url,
               url: "#{session.url}/element/#{element_id}",
               driver: Wallaby.Selenium
             }
    end
  end

  describe "set_value/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/value",
        fn conn ->
          conn = parse_body(conn)
          assert conn.body_params == %{"value" => [value]}

          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => nil
          })
        end
      )

      assert {:ok, nil} = Client.set_value(element, value)
    end

    test "when the server doesn't send a value property", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/value",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0
          })
        end
      )

      assert {:ok, nil} = Client.set_value(element, value)
    end

    test "correctly handles a 204 response", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/value",
        fn conn ->
          send_resp(conn, 204, "")
        end
      )

      assert {:ok, nil} = Client.set_value(element, value)
    end

    test "when the server sends back a StaleElementReferenceException", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      value = "hello world"

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/value",
        fn conn ->
          send_json_resp(conn, 500, %{
            "sessionId" => session.id,
            "status" => nil,
            "value" => %{
              "class" => "org.openqa.selenium.StaleElementReferenceException"
            }
          })
        end
      )

      assert {:error, :stale_reference} = Client.set_value(element, value)
    end
  end

  describe "clear/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/clear",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => nil
          })
        end
      )

      assert {:ok, nil} = Client.clear(element)
    end

    test "when the server doesn't send a value property", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/clear",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0
          })
        end
      )

      assert {:ok, nil} = Client.clear(element)
    end

    test "correctly handles a 204 response", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/clear",
        fn conn ->
          send_resp(conn, 204, "")
        end
      )

      assert {:ok, nil} = Client.clear(element)
    end

    test "when the server sends back a StaleElementReferenceException", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/clear",
        fn conn ->
          send_json_resp(conn, 500, %{
            "sessionId" => session.id,
            "status" => nil,
            "value" => %{
              "class" => "org.openqa.selenium.StaleElementReferenceException"
            }
          })
        end
      )

      assert {:error, :stale_reference} = Client.clear(element)
    end
  end

  describe "click/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/click",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => %{}
          })
        end
      )

      assert {:ok, %{}} = Client.click(element)
    end
  end

  describe "text/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/text",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => ""
          })
        end
      )

      assert {:ok, ""} = Client.text(element)
    end
  end

  describe "page_title/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      page_title = "Wallaby rocks"

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/title",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => "#{page_title}"
          })
        end
      )

      assert {:ok, ^page_title} = Client.page_title(session)
    end
  end

  describe "attribute/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      attribute_name = "name"

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/attribute/#{attribute_name}",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => "password"
          })
        end
      )

      assert {:ok, "password"} = Client.attribute(element, "name")
    end
  end

  describe "visit/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com"

      Bypass.expect(bypass, "POST", "/session/#{session.id}/url", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"url" => url}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert :ok = Client.visit(session, url)
    end
  end

  describe "current_url/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com"

      Bypass.expect(bypass, "GET", "/session/#{session.id}/url", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => "#{url}"
        })
      end)

      assert {:ok, ^url} = Client.current_url(session)
    end
  end

  describe "current_path/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      url = "http://www.google.com/search"

      Bypass.expect(bypass, "GET", "/session/#{session.id}/url", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => "#{url}"
        })
      end)

      assert {:ok, "/search"} = Client.current_path(session)
    end
  end

  describe "selected/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/selected",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => true
          })
        end
      )

      assert {:ok, true} = Client.selected(element)
    end
  end

  describe "displayed/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/displayed",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => true
          })
        end
      )

      assert {:ok, true} = Client.displayed(element)
    end

    test "with a stale reference exception", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/displayed",
        fn conn ->
          send_json_resp(conn, 500, %{
            "sessionId" => session.id,
            "status" => 10,
            "value" => %{
              "class" => "org.openqa.selenium.StaleElementReferenceException"
            }
          })
        end
      )

      assert {:error, :stale_reference} = Client.displayed(element)
    end
  end

  describe "size/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/size",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => "not quite sure"
          })
        end
      )

      assert {:ok, "not quite sure"} = Client.size(element)
    end
  end

  describe "rect/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/rect",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => "not quite sure"
          })
        end
      )

      assert {:ok, "not quite sure"} = Client.rect(element)
    end
  end

  describe "take_screenshot/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      screenshot_data = ":)"

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/screenshot",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => "#{Base.encode64(screenshot_data)}"
          })
        end
      )

      assert ^screenshot_data = Client.take_screenshot(session)
    end
  end

  describe "cookies/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "GET", "/session/#{session.id}/cookie", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => [%{"domain" => "localhost"}]
        })
      end)

      assert {:ok, [%{"domain" => "localhost"}]} = Client.cookies(session)
    end
  end

  describe "set_cookie/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      key = "tester"
      value = "McTestington"

      Bypass.expect(bypass, "POST", "/session/#{session.id}/cookie", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"cookie" => %{"name" => key, "value" => value}}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => []
        })
      end)

      assert {:ok, []} = Client.set_cookie(session, key, value)
    end
  end

  describe "set_cookie/4" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      key = "tester"
      value = "McTestington"
      expiry = DateTime.utc_now() |> DateTime.to_unix() |> Kernel.+(1000)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/cookie", fn conn ->
        conn = parse_body(conn)

        assert conn.body_params == %{
                 "cookie" => %{
                   "name" => key,
                   "value" => value,
                   "path" => "/index.html",
                   "domain" => "example.com",
                   "secure" => true,
                   "httpOnly" => true,
                   "expiry" => expiry
                 }
               }

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => []
        })
      end)

      assert {:ok, []} =
               Client.set_cookie(session, key, value,
                 path: "/index.html",
                 domain: "example.com",
                 secure: true,
                 httpOnly: true,
                 expiry: expiry
               )
    end
  end

  describe "set_window_size/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      height = 600
      width = 400

      Bypass.expect(bypass, "POST", "/session/#{session.id}/window/current/size", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"height" => height, "width" => width}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.set_window_size(session, width, height)
    end
  end

  describe "get_window_size/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "GET", "/session/#{session.id}/window/current/size", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{
            "height" => 600,
            "width" => 400
          }
        })
      end)

      assert {:ok, %{"height" => 600, "width" => 400}} == Client.get_window_size(session)
    end
  end

  describe "set_window_position/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      x_coordinate = 600
      y_coordinate = 400

      Bypass.expect(bypass, "POST", "/session/#{session.id}/window/current/position", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"x" => x_coordinate, "y" => y_coordinate}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.set_window_position(session, x_coordinate, y_coordinate)
    end
  end

  describe "get_window_position/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "GET", "/session/#{session.id}/window/current/position", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{
            "x" => 600,
            "y" => 400
          }
        })
      end)

      assert {:ok, %{"x" => 600, "y" => 400}} == Client.get_window_position(session)
    end
  end

  describe "maximize_window/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/window/current/maximize", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} == Client.maximize_window(session)
    end
  end

  describe "execute_script/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/execute", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"script" => "localStorage.clear()", "args" => [2, "a"]}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => nil
        })
      end)

      assert {:ok, nil} = Client.execute_script(session, "localStorage.clear()", [2, "a"])
    end
  end

  describe "send_keys/2" do
    test "with a Session", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      keys = ["abc", :tab]

      Bypass.expect(bypass, "POST", "/session/#{session.id}/keys", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == Wallaby.Helpers.KeyCodes.json(keys) |> Jason.decode!()

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => nil
        })
      end)

      assert {:ok, nil} = Client.send_keys(session, keys)
    end

    test "with an Element", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      keys = ["abc", :tab]

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/element/#{element.id}/value",
        fn conn ->
          conn = parse_body(conn)

          assert conn.body_params == Wallaby.Helpers.KeyCodes.json(keys) |> Jason.decode!()

          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => nil
          })
        end
      )

      assert {:ok, nil} = Client.send_keys(element, keys)
    end
  end

  describe "log/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/log", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"type" => "browser"}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => []
        })
      end)

      assert {:ok, []} = Client.log(session)
    end
  end

  describe "page_source/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      page_source = "<html></html>"

      Bypass.expect(bypass, "GET", "/session/#{session.id}/source", fn conn ->
        conn = parse_body(conn)

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => "#{page_source}"
        })
      end)

      assert {:ok, ^page_source} = Client.page_source(session)
    end
  end

  describe "window_handles/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "GET", "/session/#{session.id}/window_handles", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => ["some-window-handle", "other-window-handle"]
        })
      end)

      assert {:ok, ["some-window-handle", "other-window-handle"]} = Client.window_handles(session)
    end
  end

  describe "window_handle/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "GET", "/session/#{session.id}/window_handle", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => "my-window-handle"
        })
      end)

      assert {:ok, "my-window-handle"} = Client.window_handle(session)
    end
  end

  describe "focus_window/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      window_handle_id = "my-window-handle"

      Bypass.expect(bypass, "POST", "/session/#{session.id}/window", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"name" => window_handle_id, "handle" => window_handle_id}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.focus_window(session, window_handle_id)
    end
  end

  describe "close_window/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "DELETE", "/session/#{session.id}/window", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.close_window(session)
    end
  end

  describe "focus_frame/2" do
    test "sends the correct request to the server when passed an element", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      frame_element = build_element_for_session(session, "frame-element-id")

      Bypass.expect(bypass, "POST", "/session/#{session.id}/frame", fn conn ->
        conn = parse_body(conn)

        assert conn.body_params == %{
                 "id" => %{
                   "ELEMENT" => frame_element.id,
                   @web_element_identifier => frame_element.id
                 }
               }

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.focus_frame(session, frame_element)
    end

    test "sends the correct request to the server when switching to default frame", %{
      bypass: bypass
    } do
      session = build_session_for_bypass(bypass)
      frame_id = nil

      Bypass.expect(bypass, "POST", "/session/#{session.id}/frame", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"id" => frame_id}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.focus_frame(session, frame_id)
    end

    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      frame_id = 1

      Bypass.expect(bypass, "POST", "/session/#{session.id}/frame", fn conn ->
        conn = parse_body(conn)

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.focus_frame(session, frame_id)
    end
  end

  describe "focus_parent_frame/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/frame/parent", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.focus_parent_frame(session)
    end
  end

  describe "move_mouse_to/4" do
    test "sends the correct request to the server when only element is not nil", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/moveto", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"element" => element.id}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.move_mouse_to(nil, element)
    end

    test "sends the correct request to the server when session and offsets are given", %{
      bypass: bypass
    } do
      session = build_session_for_bypass(bypass)
      {x_offset, y_offset} = {20, 30}

      Bypass.expect(bypass, "POST", "/session/#{session.id}/moveto", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"xoffset" => x_offset, "yoffset" => y_offset}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.move_mouse_to(session, nil, x_offset, y_offset)
    end

    test "sends the correct request to the server when element and offsets are given", %{
      bypass: bypass
    } do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)
      {x_offset, y_offset} = {20, 30}

      Bypass.expect(bypass, "POST", "/session/#{session.id}/moveto", fn conn ->
        conn = parse_body(conn)

        assert conn.body_params == %{
                 "element" => element.id,
                 "xoffset" => x_offset,
                 "yoffset" => y_offset
               }

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.move_mouse_to(nil, element, x_offset, y_offset)
    end
  end

  describe "click/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/click", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"button" => 0}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.click(session, :left)
    end
  end

  describe "double_click/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/doubleclick", fn conn ->
        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.double_click(session)
    end
  end

  describe "button_down/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/buttondown", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"button" => 0}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.button_down(session, :left)
    end
  end

  describe "button_up/2" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/buttonup", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"button" => 0}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.button_up(session, :left)
    end
  end

  describe "touch_down/4" do
    test "sends the correct request to the server when element is not specified", %{
      bypass: bypass
    } do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/touch/down", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"x" => 50, "y" => 20}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.touch_down(session, nil, 50, 20)
    end

    test "sends the correct request to the server when element is specified", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/location",
        fn conn ->
          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => %{"x" => 50, "y" => 20}
          })
        end
      )

      Bypass.expect(
        bypass,
        "POST",
        "/session/#{session.id}/touch/down",
        fn conn ->
          conn = parse_body(conn)

          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => %{}
          })
        end
      )

      assert {:ok, %{}} = Client.touch_down(nil, element)
    end
  end

  describe "touch_up/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/touch/up", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"x" => 0, "y" => 0}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.touch_up(session)
    end
  end

  describe "tap/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/touch/click", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"element" => element.id}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.tap(element)
    end
  end

  describe "touch_move/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/touch/move", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"x" => 50, "y" => 40}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.touch_move(session, 50, 40)
    end
  end

  describe "touch_scroll/3" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(bypass, "POST", "/session/#{session.id}/touch/scroll", fn conn ->
        conn = parse_body(conn)
        assert conn.body_params == %{"element" => element.id, "xoffset" => 50, "yoffset" => 40}

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{}
        })
      end)

      assert {:ok, %{}} = Client.touch_scroll(element, 50, 40)
    end
  end

  describe "element_size/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(bypass, "GET", "/session/#{session.id}/element/#{element.id}/size", fn conn ->
        conn = parse_body(conn)

        send_json_resp(conn, 200, %{
          "sessionId" => session.id,
          "status" => 0,
          "value" => %{"width" => 10, "height" => 20}
        })
      end)

      assert {:ok, {10, 20}} = Client.element_size(element)
    end
  end

  describe "element_location/1" do
    test "sends the correct request to the server", %{bypass: bypass} do
      session = build_session_for_bypass(bypass)
      element = build_element_for_session(session)

      Bypass.expect(
        bypass,
        "GET",
        "/session/#{session.id}/element/#{element.id}/location",
        fn conn ->
          conn = parse_body(conn)

          send_json_resp(conn, 200, %{
            "sessionId" => session.id,
            "status" => 0,
            "value" => %{"x" => 50, "y" => 20}
          })
        end
      )

      assert {:ok, {50, 20}} = Client.element_location(element)
    end
  end

  defp build_session_for_bypass(bypass, session_id \\ "my-sample-session") do
    session_url = bypass_url(bypass, "/session/#{session_id}")

    %Session{
      driver: Wallaby.Selenium,
      id: session_id,
      session_url: session_url,
      url: session_url
    }
  end

  defp build_element_for_session(session, element_id \\ ":wdc:abc123") do
    %Element{
      driver: Wallaby.Selenium,
      id: element_id,
      parent: session,
      session_url: session.url,
      url: "#{session.url}/element/#{element_id}"
    }
  end
end
