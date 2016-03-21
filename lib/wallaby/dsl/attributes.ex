defmodule Wallaby.DSL.Attributes do
  alias Wallaby.Session
  alias Wallaby.Driver

  def text(node) do
    Driver.text(node)
  end

  def attr(node, name) do
    Driver.attribute(node, name)
  end

  def selected(node) do
    Driver.selected(node)
  end
end
