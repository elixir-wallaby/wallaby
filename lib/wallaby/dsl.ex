defmodule Wallaby.DSL do
  @moduledoc false

  defmacro __using__([]) do
    quote do
      import Wallaby.DSL.Navigation
      import Wallaby.DSL.Finders
      import Wallaby.DSL.Attributes
      import Wallaby.DSL.Actions
      import Wallaby.DSL.Matchers
    end
  end
end
