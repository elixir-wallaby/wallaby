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
        |> visit("/index.html")
        |> Browser.cookies()
        |> hd()

      assert cookie["name"] == "api_token"
      assert cookie["value"] == "abc123"
      assert cookie["path"] == "/"
      assert cookie["secure"] == false
      assert cookie["httpOnly"] == false
    end

    test "without visiting a page first throws an error", %{session: session} do
      assert_raise CookieError, fn ->
        session
        |> Browser.set_cookie("other_cookie", "test")
      end
    end
  end

  describe "set_cookie/4" do
    test "sets a cookie in the browser", %{session: session} do
      expiry = DateTime.utc_now() |> DateTime.to_unix() |> Kernel.+(1000)

      cookie =
        session
        |> visit("/")
        |> Browser.set_cookie("api_token", "abc123",
          path: "/index.html",
          secure: true,
          httpOnly: true,
          expiry: expiry
        )
        |> visit("/index.html")
        |> Browser.cookies()
        |> hd()

      assert cookie["name"] == "api_token"
      assert cookie["value"] == "abc123"
      assert cookie["path"] == "/index.html"
      assert cookie["secure"] == true
      assert cookie["httpOnly"] == true
      assert cookie["expiry"] == expiry
    end

    test "without visiting a page first throws an error", %{session: session} do
      assert_raise CookieError, fn ->
        session
        |> Browser.set_cookie("other_cookie", "test", secure: true, httpOnly: true)
      end
    end
  end
end
