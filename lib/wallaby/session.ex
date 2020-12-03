defmodule Wallaby.Session do
  @moduledoc false

  @type t :: %__MODULE__{
          id: String.t(),
          session_url: String.t(),
          url: String.t(),
          server: pid | :none,
          screenshots: list,
          driver: module,
          capabilities: map(),
          cookies: [String.t()]
        }

  defstruct [
    :id,
    :url,
    :session_url,
    :driver,
    :capabilities,
    cookies: [],
    server: :none,
    screenshots: []
  ]
end
