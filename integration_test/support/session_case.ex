defmodule Wallaby.Integration.SessionCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
      import Wallaby.Integration.SessionCase
    end
  end

  setup :inject_test_session

  @doc """
  Starts a test session with the default opts for the given driver
  """
  def start_test_session(opts \\ []) do
    retry(2, fn -> Wallaby.start_session(opts) end)
  end

  @doc """
  Injects a test session into the test context
  """
  def inject_test_session(%{skip_test_session: true}), do: :ok

  def inject_test_session(_context) do
    {:ok, session} = start_test_session()

    {:ok, %{session: session}}
  end

  defp retry(0, f), do: f.()

  defp retry(times, f) do
    case f.() do
      {:ok, session} ->
        {:ok, session}

      _ ->
        Process.sleep(250)
        retry(times - 1, f)
    end
  end
end
