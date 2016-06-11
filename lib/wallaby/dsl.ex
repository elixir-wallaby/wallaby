defmodule Wallaby.DSL do
  @moduledoc false

  defmacro __using__([]) do
    quote do
      import Wallaby.Node
      import Wallaby.Session
      import Wallaby.DSL.Actions
    end
  end
end
