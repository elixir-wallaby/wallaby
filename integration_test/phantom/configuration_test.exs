defmodule Wallaby.Integration.Phantom.ConfigurationTest do
  use Wallaby.Integration.SessionCase, async: false

  import Wallaby.Query, only: [button: 1]

  setup :ensure_settings_are_reset

  test "js errors can be disabled", %{session: session} do
    Application.put_env(:wallaby, :js_errors, false)

    session
    |> visit("/errors.html")
    |> click(button("Throw an Error"))
    |> assert
  end

  def ensure_settings_are_reset(_) do
    orig_js_errors = Application.fetch_env(:wallaby, :js_errors)

    on_exit(fn ->
      reset_setting(:wallaby, :js_errors, orig_js_errors)
    end)
  end

  defp reset_setting(app, setting, {:ok, value}) do
    Application.put_env(app, setting, value)
  end

  defp reset_setting(app, setting, :error) do
    Application.delete_env(app, setting)
  end
end
