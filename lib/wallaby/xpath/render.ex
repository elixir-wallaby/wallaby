defmodule Wallaby.XPath.Render do
  def render({:attr, attr, value}) do
    "@#{attr}='#{value}'"
  end

  def render({:descendant, value}) do
    "//#{value}"
  end

  def render({:descendant, value, predicate}) do
    render({:descendant, value}) <> render({:predicate, predicate})
  end

  def render({:union, nodes}) when is_list(nodes) do
    query =
      nodes
      |> Enum.map(&render/1)
      |> Enum.join("|")

    "(" <> query <> ")"
  end

  def render({:union, nodes, predicate}) when is_list(nodes) do
    render({:union, nodes}) <> render({:predicate, predicate})
  end

  def render({:any, nodes}) do
    query =
      nodes
      |> Enum.map(&render/1)
      |> Enum.join(" or ")

    "(" <> query <> ")"
  end

  def render({:not, nodes}) do
    "not" <> render({:any, nodes})
  end

  def render({:predicate, predicate}) do
    "[" <> render(predicate) <> "]"
  end

  def render({:and, list}) when is_list(list) do
    list
    |> Enum.map(&render/1)
    |> Enum.join(" and ")
  end
end
