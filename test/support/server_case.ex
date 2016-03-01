defmodule Wallaby.ServerCase do
  use ExUnit.CaseTemplate

  setup _tags do
    {:ok, server} = Wallaby.TestServer.start

    on_exit fn ->
      Wallaby.TestServer.stop(server)
    end
    {:ok, %{server: server}}
  end
end
