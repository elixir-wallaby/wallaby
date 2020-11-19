defmodule Wallaby.HttpClientCase do
  use ExUnit.CaseTemplate

  import Plug.Conn

  using do
    quote do
      import Plug.Conn
      import Wallaby.HttpClientCase

      setup [:start_bypass]
    end
  end

  @doc """
  Starts a bypass session and inserts it into the test session
  """
  def start_bypass(_) do
    {:ok, bypass: Bypass.open()}
  end

  @doc """
  Builds a url from the current bypass session
  """
  def bypass_url(bypass), do: "http://localhost:#{bypass.port}"

  def bypass_url(bypass, path) do
    "#{bypass_url(bypass)}#{path}"
  end

  @doc """
  Parses the body of an incoming http request
  """
  def parse_body(conn) do
    opts = Plug.Parsers.init(parsers: [:urlencoded, :json], json_decoder: Jason)
    Plug.Parsers.call(conn, opts)
  end

  @doc """
  Sends a response with the json content type
  """
  @spec send_json_resp(Conn.t(), Conn.status(), term) :: Conn.t()
  def send_json_resp(conn, status_code, body) when is_binary(body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, body)
  end

  def send_json_resp(conn, status_code, body) do
    send_json_resp(conn, status_code, Jason.encode!(body))
  end
end
