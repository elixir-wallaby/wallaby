defmodule Wallaby.ServerTest do
  use ExUnit.Case, async: true

  alias Wallaby.Server

  setup do
    {:ok, server} = Server.start_link([])

    local_storage = Server.get_local_storage_dir(server)
    on_exit fn ->
      File.rm_rf(local_storage)
    end

    {:ok, server: server}
  end

  test "it can start a server", %{server: server}  do
    assert Server.get_base_url(server) =~ ~r"http://localhost:\d+/"
  end

  test "separate servers do not share local storage", %{server: server} do
    {:ok, other_server} = Server.start_link([])

    local_storage = Server.get_local_storage_dir(server)
    other_local_storage = Server.get_local_storage_dir(other_server)

    # Remove the other directory before asserting so we can ensure deletion is successful
    File.rm_rf(other_local_storage)

    assert local_storage != other_local_storage
  end
end
