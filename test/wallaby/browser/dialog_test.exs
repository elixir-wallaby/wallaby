defmodule Wallaby.Browser.DialogTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "dialogs.html")
    {:ok, %{page: page}}
  end

  describe "accept_dialogs/1" do
    test "accept window.alert", %{page: page} do
      result = page
      |> accept_dialogs()
      |> click(Query.link("Alert"))
      |> find(Query.css("#result"))
      |> Element.text()
      assert result == "Alert accepted"
    end

    test "accept window.confirm", %{page: page} do
      result = page
      |> accept_dialogs()
      |> click(Query.link("Confirm"))
      |> find(Query.css("#result"))
      |> Element.text()
      assert result == "Confirm returned true"
    end

    test "accept window.prompt", %{page: page} do
      result = page
      |> accept_dialogs()
      |> click(Query.link("Prompt"))
      |> find(Query.css("#result"))
      |> Element.text()
      assert result == "Prompt returned default"
    end

    test "overrides dismiss_dialogs/1", %{page: page} do
      result = page
      |> dismiss_dialogs()
      |> accept_dialogs()
      |> click(Query.link("Confirm"))
      |> find(Query.css("#result"))
      |> Element.text()
      assert result == "Confirm returned true"
    end
  end

  describe "dismiss_dialogs/1" do
    test "dismiss window.alert", %{page: page} do
      result = page
      |> dismiss_dialogs()
      |> click(Query.link("Alert"))
      |> find(Query.css("#result"))
      |> Element.text()
      assert result == "Alert accepted"
    end

    test "dismiss window.confirm", %{page: page} do
      result = page
      |> dismiss_dialogs()
      |> click(Query.link("Confirm"))
      |> find(Query.css("#result"))
      |> Element.text()
      assert result == "Confirm returned false"
    end

    test "dismiss window.prompt", %{page: page} do
      result = page
      |> dismiss_dialogs()
      |> click(Query.link("Prompt"))
      |> find(Query.css("#result"))
      |> Element.text()
      assert result == "Prompt returned null"
    end

    test "overrides accept_dialogs/1", %{page: page} do
      result = page
      |> accept_dialogs()
      |> dismiss_dialogs()
      |> click(Query.link("Confirm"))
      |> find(Query.css("#result"))
      |> Element.text()
      assert result == "Confirm returned false"
    end
  end

  describe "accept_alert/2" do
    test "accept window.alert and get message", %{page: page} do
      message = accept_alert page, fn(p) ->
        click(p, Query.link("Alert"))
      end

      result = page
      |> find(Query.css("#result"))
      |> Element.text()

      assert message == "This is an alert!"
      assert result == "Alert accepted"
    end
  end

  describe "accept_confirm/2" do
    test "accept window.confirm and get message", %{page: page} do
      message = accept_confirm page, fn(p) ->
        click(p, Query.link("Confirm"))
      end

      result = page
      |> find(Query.css("#result"))
      |> Element.text()

      assert message == "Are you sure?"
      assert result == "Confirm returned true"
    end
  end

  describe "dismiss_confirm/2" do
    test "dismiss window.confirm and get message", %{page: page} do
      message = dismiss_confirm page, fn(p) ->
        click(p, Query.link("Confirm"))
      end

      result = page
      |> find(Query.css("#result"))
      |> Element.text()

      assert message == "Are you sure?"
      assert result == "Confirm returned false"
    end
  end

  describe "accept_prompt/3" do
    test "accept window.prompt with value and get message", %{page: page} do
      message = accept_prompt page, [with: "Wallaby"], fn(p) ->
        click(p, Query.link("Prompt"))
      end

      result = page
      |> find(Query.css("#result"))
      |> Element.text()

      assert message == "What's your name?"
      assert result == "Prompt returned Wallaby"
    end

    test "accept window.prompt with default", %{page: page} do
      accept_prompt page, fn(p) ->
        click(p, Query.link("Prompt"))
      end

      result = page
      |> find(Query.css("#result"))
      |> Element.text()

      assert result == "Prompt returned default"
    end
  end

  describe "dismiss_prompt/2" do
    test "dismiss window.prompt and get message", %{page: page} do
      message = dismiss_prompt page, fn(p) ->
        click(p, Query.link("Prompt"))
      end

      result = page
      |> find(Query.css("#result"))
      |> Element.text()

      assert message == "What's your name?"
      assert result == "Prompt returned null"
    end
  end
end
