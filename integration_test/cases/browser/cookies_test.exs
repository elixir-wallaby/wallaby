defmodule Wallaby.Integration.Browser.CookiesTest do
  use Wallaby.Integration.SessionCase, async: true

  alias Wallaby.CookieError

  describe "cookies/1" do
    test "returns all of the cookies in the browser", %{session: session} do
      list =
        session
        |> visit("/")
        |> Browser.cookies()

      assert list == []
    end
  end

  describe "set_cookie/3" do
    test "sets a cookie in the browser", %{session: session} do
      cookie =
        session
        |> visit("/")
        |> Browser.set_cookie("api_token", "abc123")
        |> visit("/")
        |> Browser.cookies()
        |> hd()

      assert cookie["name"] == "api_token"
      assert cookie["value"] == "abc123"
    end

    test "without visiting a page first throws an error", %{session: session} do
      assert_raise CookieError, fn ->
        session
        |> Browser.set_cookie("other_cookie", "test")
      end
    end
  end
end
