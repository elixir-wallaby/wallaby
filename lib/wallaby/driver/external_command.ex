defmodule Wallaby.Driver.ExternalCommand do
  @moduledoc false

  @type t :: %__MODULE__{
          executable: String.t(),
          args: [String.t()]
        }

  defstruct [:executable, args: []]
end
