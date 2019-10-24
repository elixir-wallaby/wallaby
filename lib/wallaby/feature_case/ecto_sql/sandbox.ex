unless Code.ensure_loaded?(Ecto.Adapters.SQL.Sandbox) do
  defmodule Ecto.Adapters.SQL.Sandbox do
    @moduledoc false

    def checkout(_repo), do: nil
    def mode(_repo, _mode), do: nil
  end
end
