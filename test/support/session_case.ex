defmodule Wallaby.SessionCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
    end
  end

  setup_all _tags do
    {:ok, server} = Wallaby.TestServer.start

    on_exit fn ->
      Wallaby.TestServer.stop(server)
    end

    {:ok, %{server: server}}
  end

  setup do
    {:ok, session} = Wallaby.start_session

    on_exit fn ->
      Wallaby.end_session(session)
    end

    {:ok, %{session: session}}
  end
end
