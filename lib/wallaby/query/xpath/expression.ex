defmodule Wallaby.Query.XPath.Expression do
  @moduledoc false

  @doc """
  label which next contains a string
  """
  def label(query) do
    ~s{label[contains(normalize-space(string(.)), "#{query}")]}
  end

  @doc """
  id or name attributes match string
  """
  def id_or_name(query) do
    ~s{(./@id = "#{query}" or ./@name = "#{query}")}
  end
end
