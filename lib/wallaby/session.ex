defmodule Wallaby.Session do
  @moduledoc false

  @type t :: %__MODULE__{
    id: String.t,
    session_url: String.t,
    url: String.t,
    server: pid | nil,
    screenshots: list,
    driver: module
  }

  defstruct [:id, :url, :session_url, :server, :driver, screenshots: []]

  def set_window_size(parent, x, y) do
    IO.warn "set_window_size/3 has been deprecated. Please use Browser.resize_window/3"

    Wallaby.Browser.resize_window(parent, x, y)
  end
end
