defmodule Wallaby.SessionTest do
  use Wallaby.ServerCase, async: false
  use Wallaby.DSL

  setup do
    {:ok, session} = Wallaby.start_session

    on_exit fn ->
      Wallaby.end_session(session)
    end

    {:ok, %{session: session}}
  end

  test "click through to another page", %{server: server, session: session} do
    session
    |> visit(server.base_url)
    |> click_link("Page 1")

    element =
      session
      |> find(".blue")

    assert element
  end

  test "clicking button type[submit] via button text (submits form)", %{server: server, session: session} do
    current_url =
      session
      |> visit(server.base_url <> "forms.html")
      |> click_button("Submit button")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button type[submit] via name (submits form)", %{server: server, session: session} do
    current_url =
      session
      |> visit(server.base_url <> "forms.html")
      |> click_button("button-submit")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button type[submit] via id (submits form)", %{server: server, session: session} do
    current_url =
      session
      |> visit(server.base_url <> "forms.html")
      |> click_button("button-submit-id")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button type[button] via button text (resets input via JS)", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "Button button")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking button type[button] via name (resets input via JS)", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "button-button")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking button type[button] via id (resets input via JS)", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "button-button-id")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking button type[reset] via button text resets form", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "Reset button")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking button type[reset] via name resets form", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "button-reset")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking button type[reset] via id resets form", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "button-reset-id")

    assert find(session, "#name_field") |> has_value?("")
  end
  
  test "clicking input type[submit] via button text submits form", %{server: server, session: session} do
    current_url =
      session
      |> visit(server.base_url <> "forms.html")
      |> click_button("Submit input")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking input type[submit] via name submits form", %{server: server, session: session} do
    current_url =
      session
      |> visit(server.base_url <> "forms.html")
      |> click_button("input-submit")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking input type[submit] via id submits form", %{server: server, session: session} do
    current_url =
      session
      |> visit(server.base_url <> "forms.html")
      |> click_button("input-submit-id")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking input type[button] via button text resets input via JS", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "Button input")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking input type[button] via name resets input via JS", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "input-button")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking input type[button] via id resets input via JS", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "input-button-id")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking input type[reset] via button text resets form", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "Reset input")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking input type[reset] via name resets form", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "input-reset")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking input type[reset] via id resets form", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Erlich Bachman")

    assert find(session, "#name_field") |> has_value?("Erlich Bachman")

    click_button(session, "input-reset-id")

    assert find(session, "#name_field") |> has_value?("")
  end

  test "clicking input type[image] via name submits form", %{server: server, session: session} do
    current_url =
      session
      |> visit(server.base_url <> "forms.html")
      |> click_button("input-image")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking input type[image] via id submits form", %{server: server, session: session} do
    current_url =
      session
      |> visit(server.base_url <> "forms.html")
      |> click_button("input-image-id")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "navigating by path only", %{session: session, server: server} do
    Application.put_env(:wallaby, :base_url, server.base_url)
    session
    |> visit("page_1.html")

    element =
      session
      |> find(".blue")

    assert element
    Application.put_env(:wallaby, :base_url, nil)
  end

  test "visit/2 with a relative url and no base url raises exception", %{session: session, server: _server} do
    assert_raise(Wallaby.NoBaseUrl, fn ->
      Application.put_env(:wallaby, :base_url, nil)
      session
      |> visit("/page_1.html")
    end)
  end

  test "visit/2 with an absolute path does not use the base url", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "/page_1.html")

    assert has_css?(session, "#visible")
  end

  test "taking screenshots", %{session: session, server: server} do
    node =
      session
      |> visit(server.base_url)
      |> take_screenshot
      |> find("#header")
      |> take_screenshot

    screenshots =
      node
      |> Map.get(:session)
      |> Map.get(:screenshots)

    assert Enum.count(screenshots) == 2

    Enum.each(screenshots, fn(path) ->
      assert File.exists? path
    end)

    File.rm_rf! "#{File.cwd!}/screenshots"
  end

  test "gets the current_url of the session", %{server: server, session: session}  do
    current_url =
      session
      |> visit(server.base_url)
      |> click_link("Page 1")
      |> get_current_url

    assert current_url == "http://localhost:#{URI.parse(current_url).port}/page_1.html"
  end

  test "gets the current_path of the session", %{server: server, session: session}  do
    current_path =
      session
      |> visit(server.base_url)
      |> click_link("Page 1")
      |> get_current_path

    assert current_path == "/page_1.html"
  end

  test "manipulating window size", %{session: session, server: server} do
    window_size =
      session
      |> visit(server.base_url)
      |> set_window_size(1234, 1234)
      |> get_window_size

    assert window_size == %{"height" => 1234, "width" => 1234}
  end
end
