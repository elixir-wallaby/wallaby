defmodule Wallaby.XPath.Builder do
  def descendants(list) when is_list(list) do
    list
    |> Enum.map(&descendant/1)
  end

  def descendant(item) when is_binary(item) do
    {:descendant, item}
  end

  def union(nodes, predicate) do
    {:union, nodes, predicate}
  end

  def all(list) when is_list(list) do
    {:and, list}
  end

  def any(list) when is_list(list) do
    {:any, list}
  end

  @doc """
  Returns a list of noted values.
  """
  def none(exclusions), do: {:not, exclusions}

  @doc """
  Returns a list of tuples with the attribute and value of the list
  """
  def attr(a, list) when is_list(list) do
    list
    |> Enum.map(&attr(a, &1))
  end
  def attr(a, item) when is_binary(item) do
    {:attr, a, item}
  end
end
