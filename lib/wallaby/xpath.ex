defmodule Wallaby.XPath do
  @type query :: String.t
  @type xpath :: String.t
  @type name  :: query
  @type id    :: query
  @type label :: query

  import Wallaby.XPath.Builder
  import Wallaby.XPath.Render

  @doc """
  XPath for links
  this xpath is gracious ripped from capybara via
  https://github.com/jnicklas/xpath/blob/master/lib/xpath/html.rb
  """
  def link(lnk) do
    ".//a[./@href][(((./@id = '#{lnk}' or contains(normalize-space(string(.)), '#{lnk}')) or contains(./@title, '#{lnk}')) or .//img[contains(./@alt, '#{lnk}')])]"
  end

  def radio_button(query) do
    nodes = descendants(["input"])
    predicate = all([any(attr("type", ["radio"])), field_locator(query)])

    union(nodes, predicate)
    |> render
  end

  @doc """
  Match any `input` or `textarea` that can be filled with text.
  Excludes any inputs with types of `submit`, `image`, `radio`, `checkbox`,
  `hidden`, or `file`.
  """
  @spec fillable_field(name) :: xpath
  @spec fillable_field(id) :: xpath
  @spec fillable_field(label) :: xpath
  def fillable_field(query) when is_binary(query) do
    nodes = descendants(fillable_fields)
    predicate = all([none(unfillable_fields), field_locator(query)])

    union(nodes, predicate)
    |> render
  end

  defp fillable_fields do
    ["textarea", "input"]
  end

  defp unfillable_fields do
    attr("type", ["checkbox", "submit", "button"])
  end

  defp field_locator(query) do
    any([attr("id", query), attr("name", query)])
  end
end
