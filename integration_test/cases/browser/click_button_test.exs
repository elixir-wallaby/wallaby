defmodule Wallaby.Integration.Browser.Actions.ClickButtonTest do
  use Wallaby.Integration.SessionCase, async: true

  alias Wallaby.Integration.Pages.IndexPage
  import Wallaby.Query, only: [button: 1, button: 2, css: 1]

  setup %{session: session} do
    page =
      session
      |> visit("forms.html")

    {:ok, page: page}
  end

  test "clicking button with no type via button text (submits form)", %{page: page} do
    current_url =
      page
      |> click(button("button with no type"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button with no type via name (submits form)", %{page: page} do
    current_url =
      page
      |> click(button("button-no-type"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button with no type via id (submits form)", %{page: page} do
    current_url =
      page
      |> click(button("button-no-type-id"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button type[submit] via button text (submits form)", %{page: page} do
    current_url =
      page
      |> click(button("Submit button"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button type[submit] via name (submits form)", %{page: page} do
    current_url =
      page
      |> click(button("button-submit"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button type[submit] via id (submits form)", %{page: page} do
    current_url =
      page
      |> click(button("button-submit-id"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking button type[button] via button text (resets input via JS)", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("Button button"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking button type[button] via name (resets input via JS)", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("button-button"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking button type[button] via id (resets input via JS)", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("button-button-id"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking button type[reset] via button text resets form", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("Reset button"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking button type[reset] via name resets form", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("button-reset"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking button type[reset] via id resets form", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("button-reset-id"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking input type[submit] via button text submits form", %{page: page} do
    current_url =
      page
      |> click(button("Submit input"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking input type[submit] via name submits form", %{page: page} do
    current_url =
      page
      |> click(button("input-submit"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking input type[submit] via id submits form", %{page: page} do
    current_url =
      page
      |> click(button("input-submit-id"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking input type[button] via button text resets input via JS", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("Button input"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking input type[button] via name resets input via JS", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("input-button"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking input type[button] via id resets input via JS", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("input-button-id"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking input type[reset] via button text resets form", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("Reset input"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking input type[reset] via name resets form", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("input-reset"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking input type[reset] via id resets form", %{page: page} do
    page
    |> fill_in(Query.text_field("name_field"), with: "Erlich Bachman")

    assert find(page, css("#name_field")) |> has_value?("Erlich Bachman")

    click(page, button("input-reset-id"))

    assert find(page, css("#name_field")) |> has_value?("")
  end

  test "clicking input type[image] via name submits form", %{page: page} do
    current_url =
      page
      |> click(button("input-image"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "clicking input type[image] via id submits form", %{page: page} do
    current_url =
      page
      |> click(button("input-image-id"))
      |> IndexPage.ensure_page_loaded()
      |> current_url

    assert current_url =~ "http://localhost:#{URI.parse(current_url).port}/index.html"
  end

  test "waits until the button appears", %{page: page} do
    assert click(page, button("Hidden Button"))
  end

  test "throws an error if the button does not include a valid type attribute", %{page: page} do
    assert_raise Wallaby.QueryError, ~r/button has an invalid 'type'/, fn ->
      click(page, button("button with bad type", []))
    end
  end

  test "throws an error if clicking on an input with no type", %{page: page} do
    assert_raise Wallaby.QueryError, ~r/Expected (.*) 1/, fn ->
      click(page, button("input-no-type", []))
    end
  end

  test "throws an error if the button cannot be found on the page", %{page: page} do
    assert_raise Wallaby.QueryError, ~r/Expected (.*) 1/, fn ->
      click(page, button("unfound button", []))
    end
  end

  test "escapes quotes", %{page: page} do
    assert click(page, button("I'm a button"))
  end

  test "with duplicate buttons", %{page: page} do
    assert_raise Wallaby.QueryError, ~r/Expected (.*) 1/, fn ->
      page
      |> find(css(".duplicate-buttons"))
      |> click(button("Duplicate Button"))
    end
  end

  test "works with elements", %{page: page} do
    assert page
           |> find(button("I'm a button"))
           |> Element.click()
  end
end
