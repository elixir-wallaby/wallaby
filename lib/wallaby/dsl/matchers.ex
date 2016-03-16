defmodule Wallaby.DSL.Matchers do
  alias Wallaby.DSL.Attributes
  alias Wallaby.Node
  alias Wallaby.Session

  def has_value?(%Node{}=node, value) do
    Attributes.attr(node, "value") == value
  end

  def has_content?(%Node{}=node, text) when is_binary(text) do
    Attributes.text(node) == text
  end

  def checked?(_) do
    false
  end
end
