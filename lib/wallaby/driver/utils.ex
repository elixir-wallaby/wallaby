defmodule Wallaby.Driver.Utils do
  @moduledoc false

  @type port_number :: 0..65_535

  @spec find_available_port() :: port_number
  def find_available_port do
    {:ok, listen} = :gen_tcp.listen(0, [])
    {:ok, port} = :inet.port(listen)
    :gen_tcp.close(listen)
    port
  end
end
