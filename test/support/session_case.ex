defmodule Wallaby.SessionCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
    end
  end

  setup context do
    {:ok, session} = Wallaby.start_session(context: Map.take(context, [:case, :describe, :test]))

    on_exit fn ->
      Wallaby.end_session(session)
    end

    {:ok, %{session: session}}
  end
end
