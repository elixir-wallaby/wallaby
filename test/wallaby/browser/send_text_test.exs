defmodule Wallaby.Browser.SendTextTest do
  use Wallaby.SessionCase, async: true

  test "sending key presses", %{session: session} do
    session
    |> visit("/")

    session
    |> send_keys([:tab, :enter])

    assert find(session, ".blue")
  end

  describe "send_keys/3" do
    setup %{session: session} do
      page = visit(session, "forms.html")
      {:ok, %{page: page}}
    end

    test "accepts a query", %{page: page} do
      page
      |> send_keys(Query.text_field("Name"), ["Chris", :tab, "c@keathley.io"])

      assert page
      |> find(Query.text_field("Name"))
      |> has_value?("Chris")

      assert page
      |> find(Query.text_field("email"))
      |> has_value?("c@keathley.io")
    end
  end
end
