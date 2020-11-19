defmodule Wallaby.Integration.Browser.DialogTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "dialogs.html")
    {:ok, %{page: page}}
  end

  describe "accept_alert/2" do
    test "accept window.alert and get message", %{page: page} do
      message =
        accept_alert(page, fn p ->
          click(p, Query.link("Alert"))
        end)

      result =
        page
        |> find(Query.css("#result"))
        |> Element.text()

      assert message == "This is an alert!"
      assert result == "Alert accepted"
    end
  end

  describe "accept_confirm/2" do
    test "accept window.confirm and get message", %{page: page} do
      message =
        accept_confirm(page, fn p ->
          click(p, Query.link("Confirm"))
        end)

      result =
        page
        |> find(Query.css("#result"))
        |> Element.text()

      assert message == "Are you sure?"
      assert result == "Confirm returned true"
    end
  end

  describe "dismiss_confirm/2" do
    test "dismiss window.confirm and get message", %{page: page} do
      message =
        dismiss_confirm(page, fn p ->
          click(p, Query.link("Confirm"))
        end)

      result =
        page
        |> find(Query.css("#result"))
        |> Element.text()

      assert message == "Are you sure?"
      assert result == "Confirm returned false"
    end
  end

  describe "accept_prompt/2" do
    test "accept window.prompt with default value and get message", %{page: page} do
      message =
        accept_prompt(page, fn p ->
          click(p, Query.link("Prompt"))
        end)

      result =
        page
        |> find(Query.css("#result"))
        |> Element.text()

      assert message == "What's your name?"
      assert result == "Prompt returned default"
    end

    test "ensure the input value is a string", %{page: page} do
      assert_raise FunctionClauseError, fn ->
        accept_prompt(page, [with: nil], fn _ -> :noop end)
      end

      assert_raise FunctionClauseError, fn ->
        accept_prompt(page, [with: 123], fn _ -> :noop end)
      end

      assert_raise FunctionClauseError, fn ->
        accept_prompt(page, [with: :foo], fn _ -> :noop end)
      end
    end
  end

  describe "accept_prompt/3" do
    test "accept window.prompt with value and get message", %{page: page} do
      message =
        accept_prompt(page, [with: "Wallaby"], fn p ->
          click(p, Query.link("Prompt"))
        end)

      result =
        page
        |> find(Query.css("#result"))
        |> Element.text()

      assert message == "What's your name?"
      assert result == "Prompt returned Wallaby"
    end
  end

  describe "dismiss_prompt/2" do
    test "dismiss window.prompt and get message", %{page: page} do
      message =
        dismiss_prompt(page, fn p ->
          click(p, Query.link("Prompt"))
        end)

      result =
        page
        |> find(Query.css("#result"))
        |> Element.text()

      assert message == "What's your name?"
      assert result == "Prompt returned null"
    end
  end
end
