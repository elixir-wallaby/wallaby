defmodule Wallaby.Integration.Phantom.SendKeys do
  use Wallaby.Integration.SessionCase, async: true

  alias Wallaby.Phantom.Driver

  test "navigating with key presses", %{session: session} do
    session
    |> IndexPage.visit()
    |> send_keys([:tab, :enter])
    |> Page1.ensure_page_loaded()
  end
end
