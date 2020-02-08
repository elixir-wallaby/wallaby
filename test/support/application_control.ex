defmodule Wallaby.TestSupport.ApplicationControl do
  @moduledoc """
  Test helpers for starting/stopping wallaby during test setup
  """

  import ExUnit.Assertions, only: [flunk: 1]
  import ExUnit.Callbacks, only: [on_exit: 1]
  import Wallaby.SettingsTestHelpers

  @doc """
  Stops the wallaby application and ensures its restarted
  before the next test
  """
  def stop_wallaby(_) do
    Application.stop(:wallaby)

    on_exit(fn ->
      case Application.start(:wallaby) do
        result when result in [:ok, {:error, {:already_started, :wallaby}}] ->
          :ok

        result ->
          flunk("failed to restart wallaby: #{inspect(result)}")
      end
    end)
  end

  @doc """
  Set's the current driver to chromedriver

  Note: This is not safe for use with `async: true`
  """
  def set_to_chromedriver(_) do
    ensure_setting_is_reset(:wallaby, :driver)

    :ok = Application.put_env(:wallaby, :driver, Wallaby.Experimental.Chrome)
  end
end
