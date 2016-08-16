defmodule Wallaby.Driver.ConfigurationTest do
  use Wallaby.SessionCase, async: false

  test "js errors can be disabled", %{session: session, server: server} do
    Application.put_env(:wallaby, :js_errors, false)

    session
    |> visit(server.base_url <> "/errors.html")
    |> click_on("Throw an Error")
    |> assert

    Application.put_env(:wallaby, :js_errors, nil)
  end
end
