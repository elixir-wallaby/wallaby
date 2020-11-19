defmodule Wallaby.Session do
  @moduledoc false

  @type t :: %__MODULE__{
          id: String.t(),
          session_url: String.t(),
          url: String.t(),
          server: pid | :none,
          screenshots: list,
          driver: module,
          capabilities: map()
        }

  defstruct [:id, :url, :session_url, :driver, :capabilities, server: :none, screenshots: []]
end
