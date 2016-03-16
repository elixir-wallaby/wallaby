defmodule Wallaby.DSL.Matchers do
  alias Wallaby.DSL.Attributes
  alias Wallaby.Node

  def has_value?(%Node{}=node, value) do
    Attributes.attr(node, "value") == value
  end
end
