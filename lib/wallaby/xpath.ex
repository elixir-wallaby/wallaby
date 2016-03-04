defmodule Wallaby.XPath do
  @type query :: String.t
  @type xpath :: String.t
  @type name  :: query
  @type id    :: query
  @type label :: query

  import Kernel, except: [not: 1]

  # defp all(list) do
  #   "(#{union})"
  # end
  #
  # defp attr(a, opts) do
  #   opts
  #   |> Enum.map(fn(opt) -> "@#{a}='opt'" end)
  # end
  #
  # defp exclude(root, list) do
  #   exclusions =
  #     list
  #     |> Enum.join(" or ")
  #   root <> "[not(#{exclusions})]"
  # end
  #
  # defp union(xpath, list) do
  # end

  @doc """
  Match any `input` or `textarea` that can be filled with text.
  Excludes any inputs with types of `submit`, `image`, `radio`, `checkbox`,
  `hidden`, or `file`.
  """
  @spec fillable_field(name) :: xpath
  @spec fillable_field(id) :: xpath
  @spec fillable_field(label) :: xpath
  def fillable_field(query) do
    descendant(fillable_fields) ++ not(unfillable_fields) ++ field_locator(query)
  {:all,
    [{:root, "textarea"},
     {:root, "input"}],
    {:and,
      [
        {:not,
          [{"type", "checkbox"},
           {"type", "submit"},
           {"type", "button"}]},
        {:all,
          [{"id", "test"},
           {"name", "test"}]}
      ]
    }

  end
  # "(//textarea|//input)[not(@type='checkbox' or @type='submit' or @type='button') and (@id='test' or @name='name')]"

  def fillable_fields, do: ["textarea", "input"]

  def descendant(list) when is_list(list) do
    list
    |> root
  end

  def root(list) when is_list(list), do: Enum.map(&{:root, &1})

  def all(list) when is_list(list), do: {:all, list}
  #
  # def parse(list) when is_list(list) do
  #   Enum.map(&do_parse/1)
  # end
  # def parse({:not, list}) do
  #   "not(" <> Enum.join(parse(list), " or ") <> ")"
  # end
  # def parse({:and, list}) do
  #   "[" <> Enum.join(parse(list), " and ") <> "]"
  # end
  # def parse({:all, list}) do
  #   IO.inspect list
  #   "(" <> Enum.join(parse(list), "|") <> ")"
  # end
  # def parse({:root, value}) when is_binary(value) do
  #   "//#{value}"
  # end
  # def parse({name, value}) when is_binary(name) do
  #   "@#{name}='#{value}'"
  # end

  @doc """
  Returns all of the values

  iex> all(["a", "b"])
  {:all, ["a", "b"]}
  """
  def all(list) do
    [ {:all, Enum.map(list, fn(value) -> {:root, value} end)} ]
  end

  @doc """
  Returns a list of noted values.

  iex> Wallaby.XPath.exclude(["a", "b", "c"])
  {:not, ["a", "b", "c"]}
  """
  def not(exclusions), do: {:not, exclusions}

  @doc """
  Returns a list of tuples with the attribute and value of the list

  iex> attr("type", ["checkbox", "submit"])
  [{"type", "checkbox"}, {"type", "submit"}]
  """
  def attr(a, list) do
    list
    |> Enum.map(&{a, &1})
  end

  @doc """
  Returns the union of 2 xpath selectors
  iex> union([{"id", "test"}, {"name", "test"}])
  {:and, [{"id", "test"}, {"name", "test"}]}
  """
  def union(list), do: [{:and, list}]

  @doc """
  Returns xpath for finding fields (id, name, and label)

  iex> field_locator("Name")
  {:and, [{"id", "Name"}, {"name", "Name"}]}
  """
  def field_locator(query) do
    union([attr("id", query), attr("name", query)])
  end

  # [
  #   ["textarea", "input"],
  #   {:not, [{"type", "checkbox"},
  #           {"type", "submit"},
  #           {"type", "button"}]},
  #   {:and, [{"id", "test"},
  #           {"name", "some-name"}]}
  # ]
  #
  # "(//textarea|//input)[not(@type='checkbox' or @type='submit' or @type='button') and (@id='test' or @name='name')]"
end
