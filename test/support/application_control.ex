defmodule Wallaby.TestSupport.ApplicationControl do
  @moduledoc """
  Test helpers for starting/stopping wallaby during test setup
  """

  import ExUnit.Assertions, only: [flunk: 1]
  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc """
  Stops the wallaby application
  """
  def stop_wallaby(_) do
    Application.stop(:wallaby)
  end

  @doc """
  Restarts wallaby after the current test process exits.

  This ensures wallaby is restarted in a fresh state after
  a test that modifies wallaby's startup config.
  """
  def restart_wallaby_on_exit!(_) do
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
