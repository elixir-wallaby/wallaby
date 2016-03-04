defmodule Wallaby.XPathTest do
  use ExUnit.Case
  doctest Wallaby.XPath, import: true

  # @moduletag :focus

  import Kernel, except: [not: 1]
  import Wallaby.XPath

  @tag :skip
  test "fillable_field/2 with css selector" do
    # assert fillable_field("Name") == "(//input|textarea)"
    assert fillable_field("#name_field") == "(//textarea|//input)[not(@type='checkbox' or @type='submit' or @type='button') and (@id='test' or @name='name')]"
  end
  #
  # test "parse/1 parses root nodes" do
  #   query =
  #     all(["input", "textarea"])
  #   assert parse(query) == "(//input|//textarea)[not(@type='checkbox') and (@id='test')]"
  # end
  #
  # test "parse/1 parses nots" do
  #   assert parse(query) == "(//input|//textarea)[not(@type='checkbox') and (@id='test')]"
  # end

  @tag :focus
  test "parse/1 parses" do
    query =
      all(["input", "textarea"])
      ++ union([not(attr("type", ["checkbox"])), attr("id", ["test"])])

    # IO.inspect query
    assert parse(query) == "(//input|//textarea)[not(@type='checkbox') and (@id='test')]"
  end
end
