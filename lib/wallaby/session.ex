defmodule Wallaby.Session do
  @moduledoc false

  @type t :: %__MODULE__{
    id: String.t,
    session_url: String.t,
    url: String.t,
    server: pid | :none,
    screenshots: list,
    context: String.t,
    driver: module,
  }

  defstruct [:id, :url, :session_url, :driver, :context, server: :none, screenshots: []]
end
