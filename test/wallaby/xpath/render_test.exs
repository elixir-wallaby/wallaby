defmodule Wallaby.XPath.RenderTest do
  use ExUnit.Case, async: true

  import Wallaby.XPath.Render

  test "render/1 renders unions" do
    query =
      {:union, [{:descendant, "textarea"}, {:descendant, "input"}]}

    assert render(query) == "(//textarea|//input)"
  end

  test "render/1 renders unions with predicates" do
    query =
      {:union,
        [{:descendant, "textarea"}, {:descendant, "input"}],
        {:any, [{:attr, "id", "test"}]}
      }

    assert render(query) == "(//textarea|//input)[(@id='test')]"
  end

  test "render/1 renders descendants with predicates" do
    query =
      {:descendant, "textarea", {:any, [{:attr, "id", "test"}]}}

    assert render(query) == "//textarea[(@id='test')]"
  end

  test "render/1 renders nots" do
    query =
      {:not, [{:attr, "id", "test"}, {:attr, "type", "submit"}]}

    assert render(query) == "not(@id='test' or @type='submit')"
  end

  test "render/1 renders ands" do
    query =
      {:and, [{:attr, "id", "test"}, {:attr, "type", "submit"}]}

    assert render(query) == "@id='test' and @type='submit'"
  end
end
