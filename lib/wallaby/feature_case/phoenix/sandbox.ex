unless Code.ensure_loaded?(Phoenix.Ecto.SQL.Sandbox) do
  defmodule Phoenix.Ecto.SQL.Sandbox do
    @moduledoc false

    def metadata_for(_repos, _pid), do: nil
  end
end
