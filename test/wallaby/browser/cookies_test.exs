defmodule Wallaby.Browser.CookiesTest do
  use Wallaby.SessionCase, async: true

  describe "cookies/1" do
    test "returns all of the cookies in the browser", %{session: session} do
      list =
	session
	|> visit("/")
	|> Browser.cookies

      assert list == []
    end
  end

  describe "set_cookie/3" do
    test "sets a cookie in the browser", %{session: session} do
      cookie =
	session
	|> visit("/")
	|> Browser.set_cookie("api_token", "abc123")
	|> Browser.cookies
	|> hd()

      assert cookie["name"] == "api_token"
      assert cookie["value"] == "abc123"
    end
  end
end
