defmodule Wallaby.DSL.Actions.ClickButtonTest do
  use Wallaby.SessionCase, async: true

  @moduletag :focus

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
end
