defmodule Wallaby.ServerTest do
  use ExUnit.Case

  alias Wallaby.Server

  test "it can start a server" do
    {:ok, server} = Server.start_link([])
    assert Server.get_base_url(server) =~ ~r"http://localhost:\d+/"
  end
end

