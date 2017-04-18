defmodule Wallaby.Integration.SessionCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
      import Wallaby.Integration.SessionCase
    end
  end

  setup do
    {:ok, session} = start_test_session()

    on_exit fn ->
      Wallaby.end_session(session)
    end

    {:ok, %{session: session}}
  end

  @doc """
  Starts a test session with the default opts for the given driver
  """
  def start_test_session(opts \\ []) do
    session_opts = case System.get_env("WALLABY_DRIVER") do
      "phantom" ->
        []
      other ->
        raise "Unknown value for WALLABY_DRIVER environment variable: #{other}"
    end |> Keyword.merge(opts)

    Wallaby.start_session(session_opts)
  end
end
