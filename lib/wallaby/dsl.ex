defmodule Wallaby.DSL do
  @moduledoc false

  defmacro __using__([]) do
    quote do
      alias Wallaby.Query
      alias Wallaby.Browser
      alias Wallaby.Element
      import Wallaby.Browser
      require Wallaby.Browser
    end
  end
end
