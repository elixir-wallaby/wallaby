defmodule Wallaby.SettingsTestHelpers do
  @moduledoc """
  Test helpers for working with app environments
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc """
  Ensures a setting is reset for the app's environment after the test is run.
  """
  def ensure_setting_is_reset(app, setting) do
    orig_result = Application.fetch_env(app, setting)

    on_exit(fn -> reset_env(orig_result, app, setting) end)
  end

  defp reset_env({:ok, orig}, app, setting) do
    Application.put_env(app, setting, orig)
  end

  defp reset_env(:error, app, setting), do: Application.delete_env(app, setting)
end
