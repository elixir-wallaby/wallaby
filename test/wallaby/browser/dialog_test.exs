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
end
