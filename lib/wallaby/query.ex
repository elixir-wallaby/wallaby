defmodule Wallaby.Query do
  @moduledoc ~S"""
  Provides the query DSL.

  Queries are used to locate and retrieve DOM elements from a browser (see
  `Wallaby.Browser`). You create queries like so:

  ```
  Query.css(".some-css")
  Query.xpath(".//input")
  ```

  ## Form elements

  There are several custom finders for locating form elements. Each of these allows
  finding by their name, id text, or label text. This allows for more robust querying
  and decouples the query from presentation selectors like css classes.

  ```
  Query.text_field("My Name")
  Query.checkbox("Checkbox")
  Query.select("A Fancy Select Box")
  ```

  ## Query Options

  All of the query operations accept the following options:

    * `:count` - The number of elements that should be found (default: 1).
    * `:visible` - Determines if the query should return only visible elements (default: true).
    * `:text` - Text that should be found inside the element (default: nil).

  ## Re-using queries

  It is often convenient to re-use queries. The easiest way is to use module
  attributes:

  @name_field Query.text_field("User Name")
  @submit_button Query.button("Save")

  If the queries need to be dynamic then you should create a module that
  encapsulates the queries as functions:

  ```
  defmodule TodoListPage do
    def todo_list() do
      Query.css(".todo-list")
    end

    def todos(count) do
      Query.css(".todo", count: count)
    end
  end
  ```
  """
  alias __MODULE__
  alias Wallaby.Query.XPath
  alias Wallaby.Element

  defstruct method: nil,
            selector: nil,
            html_validation: nil,
            conditions: [],
            result: []

  @type method :: :css
                | :xpath
                | :link
                | :button
                | :fillable_field
                | :checkbox
                | :radio_button
                | :option
                | :select
                | :file_field
  @type selector :: String.t
  @type html_validation :: :bad_label
                         | :button_type
                         | nil
  @type conditions :: [
    count: non_neg_integer,
    text: String.t,
    visible: boolean(),
    minimum: non_neg_integer,
  ]
  @type result :: list(Element.t)
  @type opts :: nonempty_list()

  @type t :: %__MODULE__{
    method: method(),
    selector: selector(),
    html_validation: html_validation(),
    conditions: conditions(),
    result: result(),
  }

  @type compiled :: {:xpath | :css, String.t}


  def css(selector, opts \\ []) do
    %Query{
      method: :css,
      selector: selector,
      conditions: build_conditions(opts),
    }
  end

  def xpath(selector, opts \\ []) do
    %Query{
      method: :xpath,
      selector: selector,
      conditions: build_conditions(opts)
    }
  end

  def text(selector, opts \\ []) do
    %Query{
      method: :text,
      selector: selector,
      conditions: build_conditions(opts)
    }
  end

  def text_field(selector, opts \\ []) do
    %Query{
      method: :fillable_field,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label,
    }
  end

  def fillable_field(selector, opts \\ []) do
    %Query{
      method: :fillable_field,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label,
    }
  end

  def radio_button(selector, opts \\ []) do
    %Query{
      method: :radio_button,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label,
    }
  end

  def checkbox(selector, opts \\ []) do
    %Query{
      method: :checkbox,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label,
    }
  end

  def select(selector, opts \\ []) do
    %Query{
      method: :select,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label,
    }
  end

  def option(selector, opts \\ []) do
    %Query{
      method: :option,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label,
    }
  end

  def button(selector, opts \\ []) do
    %Query{
      method: :button,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :button_type,
    }
  end

  def link(selector, opts \\ []) do
    %Query{
      method: :link,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label,
    }
  end

  def file_field(selector, opts \\ []) do
    %Query{
      method: :file_field,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label,
    }
  end

  def validate(query) do
    # TODO: This should be handled with xpath if we avoid throwing the error.
    cond do
    query.conditions[:minimum] > query.conditions[:maximum] ->
      {:error, :min_max}
    !Query.visible?(query) && Query.inner_text(query) ->
      {:error, :cannot_set_text_with_invisible_elements}
    true ->
      {:ok, query}
    end
  end

  @spec compile(t) :: compiled
  def compile(%{method: :css, selector: selector}), do: {:css, selector}
  def compile(%{method: :xpath, selector: selector}), do: {:xpath, selector}
  def compile(%{method: :link, selector: selector}), do: {:xpath, XPath.link(selector)}
  def compile(%{method: :button, selector: selector}), do: {:xpath, XPath.button(selector)}
  def compile(%{method: :fillable_field, selector: selector}), do: {:xpath, XPath.fillable_field(selector)}
  def compile(%{method: :checkbox, selector: selector}), do: {:xpath, XPath.checkbox(selector)}
  def compile(%{method: :radio_button, selector: selector}), do: {:xpath, XPath.radio_button(selector)}
  def compile(%{method: :option, selector: selector}), do: {:xpath, XPath.option(selector)}
  def compile(%{method: :select, selector: selector}), do: {:xpath, XPath.select(selector)}
  def compile(%{method: :file_field, selector: selector}), do: {:xpath, XPath.file_field(selector)}
  def compile(%{method: :text, selector: selector}), do: {:xpath, XPath.text(selector)}

  def visible?(%Query{conditions: conditions}) do
    Keyword.get(conditions, :visible)
  end

  def count(%Query{conditions: conditions}) do
    Keyword.get(conditions, :count)
  end

  def inner_text(%Query{conditions: conditions}) do
    Keyword.get(conditions, :text)
  end

  def result(query) do
    cond do
      count(query) == 1 ->
        [element] = query.result
        element
      true ->
        query.result
    end
  end

  def matches_count?(%{conditions: conditions}, count) do
    cond do
      conditions[:count] == :any ->
        count > 0

      conditions[:count] ->
        conditions[:count] == count

      true ->
        !(conditions[:minimum] && conditions[:minimum] > count) &&
        !(conditions[:maximum] && conditions[:maximum] < count)
    end
  end

  defp build_conditions(opts) do
    opts
    |> add_visibility
    |> add_text
    |> add_count
  end

  defp add_visibility(opts) do
    Keyword.put_new(opts, :visible, true)
  end

  defp add_text(opts) do
    Keyword.put_new(opts, :text, nil)
  end

  defp add_count(opts) do
    cond do
      opts[:count] == nil && opts[:minimum] == nil && opts[:maximum] == nil ->
        Keyword.put(opts, :count, 1)
      true ->
        opts
        |> Keyword.put_new(:count, opts[:count])
        |> Keyword.put_new(:minimum, opts[:minimum])
        |> Keyword.put_new(:maximum, opts[:maximum])
    end
  end
end
