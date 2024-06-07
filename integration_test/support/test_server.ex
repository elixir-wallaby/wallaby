defmodule Wallaby.Integration.TestServer do
  @moduledoc false

  @config [
    port: 0,
    server_root: String.to_charlist(Path.absname("./", __DIR__)),
    document_root: String.to_charlist(Path.absname("./pages", __DIR__)),
    server_name: ~c"wallaby_test",
    directory_index: [~c"index.html"]
  ]

  defstruct [:base_url, :pid]

  def start do
    :inets.start()

    case :inets.start(:httpd, @config) do
      {:ok, pid} ->
        port = :httpd.info(pid)[:port]
        {:ok, %__MODULE__{base_url: "http://localhost:#{port}/", pid: pid}}

      error ->
        error
    end
  end

  def port(%__MODULE__{pid: pid}) do
    :httpd.info(pid)[:port]
  end

  def stop(%__MODULE__{pid: pid}) do
    :ok = :inets.stop(:httpd, pid)
  end
end
