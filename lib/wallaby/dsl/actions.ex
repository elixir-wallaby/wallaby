defmodule Wallaby.DSL.Actions do
  alias Wallaby.Node

  @doc """
  Fills in a "fillable" node with text. Input nodes are looked up by id, label text,
  or name. The specific node can also be passed in directly.
  """
  # @spec fill_in(parent, locator, [with: String.t]) :: Session.t

  def fill_in(parent, locator, with: value) when is_binary(value) do
    parent
    |> Node.find({:fillable_field, locator})
    |> Node.fill_in(with: value)

    parent
  end

  @doc """
  Clears an input field. Input nodes are looked up by id, label text, or name.
  The node can also be passed in directly.
  """
  # @spec clear(Session.t, query) :: Session.t
  # def clear(session, query) when is_binary(query) do
  #   session
  #   |> find({:fillable_field, query})
  #   |> clear()
  # end

end
