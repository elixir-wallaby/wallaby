defmodule Wallaby.Phantom.Driver.ConfigurationTest do
  use Wallaby.SessionCase, async: false

  test "js errors can be disabled", %{session: session} do
    Application.put_env(:wallaby, :js_errors, false)

    session
    |> visit("/errors.html")
    |> click_button("Throw an Error")
    |> assert

    Application.put_env(:wallaby, :js_errors, true)
  end
end
