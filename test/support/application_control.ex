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
      # Stops wallaby if it's been started so it can be
      # restarted successfully
      Application.stop(:wallaby)

      case Application.start(:wallaby) do
        :ok ->
          :ok

        result ->
          flunk("failed to restart wallaby: #{inspect(result)}")
      end
    end)
  end
end
