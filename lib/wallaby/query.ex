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
  and decouples the query from presentation selectors like CSS classes.

  ```
  Query.text_field("My Name")
  Query.checkbox("Checkbox")
  Query.select("A Fancy Select Box")
  ```

  ## Query Options

  All of the query operations accept the following options:

    * `:count` - The number of elements that should be found (default: 1).
    * `:visible` - Determines if the query should return only visible elements (default: true).
    * `:selected` - Determines if the query should return only selected elements (default: :any for selected and unselected).
    * `:text` - Text that should be found inside the element (default: nil).
    * `:at` - The position number of the element to select if multiple elements satisfy the selection criteria. (:all for all elements)

  Query options can also be set via functions by the same names:

  ```
  Query.css(".names")
  |> Query.visible(true)
  |> Query.count(3)
  ```

  ## Re-using queries

  It is often convenient to re-use queries. The easiest way is to use module
  attributes:

  ```
  @name_field Query.text_field("User Name")
  @submit_button Query.button("Save")
  ```

  If the queries need to be dynamic then you should create a module that
  encapsulates the queries as functions:

  ```
  defmodule TodoListPage do
    def todo_list do
      Query.css(".todo-list")
    end

    def todos(count) do
      Query.css(".todo", count: count)
    end
  end
  ```

  ## What does my query do?

  Wanna check out what exactly your query will do? Look no further than
  `Wallaby.Query.compile/1` - it takes a query and returns the CSS or xpath
  query that will be sent to the driver:

      iex> Wallaby.Query.compile Wallaby.Query.text("my text")
      {:xpath, ".//*[contains(normalize-space(text()), \"my text\")]"}

  So, whenever you're not sure whatever a specific query will do just compile
  it to get all the details!
  """
  alias __MODULE__
  alias Wallaby.Element
  alias Wallaby.Query.XPath

  defstruct method: nil,
            selector: nil,
            html_validation: nil,
            conditions: [],
            result: []

  @type method ::
          :css
          | :xpath
          | :link
          | :button
          | :fillable_field
          | :checkbox
          | :radio_button
          | :option
          | :select
          | :file_field
          | :attribute
  @type attribute_key_value_pair :: {String.t(), String.t()}
  @type selector ::
          String.t()
          | attribute_key_value_pair()
  @type html_validation ::
          :bad_label
          | :button_type
          | nil
  @type conditions :: [
          count: non_neg_integer,
          minimum: non_neg_integer,
          maximum: non_neg_integer,
          text: String.t() | nil,
          visible: boolean() | :any,
          selected: boolean() | :any,
          at: non_neg_integer | :all
        ]
  @type result :: list(Element.t())
  @type opts :: list()

  @type t :: %__MODULE__{
          method: method(),
          selector: selector(),
          html_validation: html_validation(),
          conditions: conditions(),
          result: result()
        }

  @type compiled :: {:xpath | :css, String.t()}

  @doc """
  Literally queries for the CSS selector you provide.
  """

  def css(selector, opts \\ []) do
    %Query{
      method: :css,
      selector: selector,
      conditions: build_conditions(opts)
    }
  end

  @doc """
  Literally queries for the xpath selector you provide.
  """
  def xpath(selector, opts \\ []) do
    %Query{
      method: :xpath,
      selector: selector,
      conditions: build_conditions(opts)
    }
  end

  @doc """
  This function can be used in one of two ways.

  The first is by providing a selector and possible options. This generates a
  query that checks if the provided text is contained anywhere.

  ## Example

    ```
    Query.text("Submit", count: 1)
    ```

  The second is by providing an existing query and a value to set as the `text`
  option.

  ## Example

    ```
    submit_button = Query.css("#submit-button")

    update_button = submit_button |> Query.text("Update")
    create_button = submit_button |> Query.text("Create")
    ```
  """
  def text(query_or_selector, value_or_opts \\ [])

  def text(%Query{} = query, value) do
    update_condition(query, :text, value)
  end

  def text(selector, opts) do
    %Query{
      method: :text,
      selector: selector,
      conditions: build_conditions(opts)
    }
  end

  @doc """
  Checks if the provided value is contained anywhere.
  """
  def value(selector, opts \\ []) do
    attribute("value", selector, opts)
  end

  @doc """
  Checks if the data attribute is contained anywhere.
  """
  def data(name, selector, opts \\ []) do
    attribute("data-#{name}", selector, opts)
  end

  @doc """
  Checks if the provided attribute, value pair is contained anywhere.
  """
  def attribute(name, value, opts \\ []) do
    %Query{
      method: :attribute,
      selector: {name, value},
      conditions: build_conditions(opts)
    }
  end

  @doc """
  See `Wallaby.Query.fillable_field/2`.
  """
  def text_field(selector, opts \\ []) do
    %Query{
      method: :fillable_field,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label
    }
  end

  @doc """
  Looks for a text input field where the provided selector is the id, name or
  placeholder of the text field itself or alternatively the id or the text of
  the label.
  """
  def fillable_field(selector, opts \\ []) do
    %Query{
      method: :fillable_field,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label
    }
  end

  @doc """
  Looks for a radio button where the provided selector is the id, name or
  placeholder of the radio button itself or alternatively the id or the text of
  the label.
  """
  def radio_button(selector, opts \\ []) do
    %Query{
      method: :radio_button,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label
    }
  end

  @doc """
  Looks for a checkbox where the provided selector is the id, name or
  placeholder of the checkbox itself or alternatively the id or the text of
  the label.
  """
  def checkbox(selector, opts \\ []) do
    %Query{
      method: :checkbox,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label
    }
  end

  @doc """
  Looks for a select box where the provided selector is the id or name of the
  select box itself or alternatively the id or the text of the label.
  """
  def select(selector, opts \\ []) do
    %Query{
      method: :select,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label
    }
  end

  @doc """
  Looks for an option that contains the given text.
  """
  def option(selector, opts \\ []) do
    %Query{
      method: :option,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label
    }
  end

  @doc """
  Looks for a button (literal button or input type button, submit, image or
  reset) where the provided selector is the id, name, value, alt or title of the
  button.
  """
  def button(selector, opts \\ []) do
    %Query{
      method: :button,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :button_type
    }
  end

  @doc """
  Looks for a link where the selector is the id, link text, title of the link
  itself or the alt of an image child node.
  """
  def link(selector, opts \\ []) do
    %Query{
      method: :link,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label
    }
  end

  @doc """
  Looks for a file input where the selector is the id or name of the file input
  itself or the id or text of the label.
  """
  def file_field(selector, opts \\ []) do
    %Query{
      method: :file_field,
      selector: selector,
      conditions: build_conditions(opts),
      html_validation: :bad_label
    }
  end

  @doc """
  Updates a query's visibility (visible if `true`, hidden if `false`).

  ## Examples

    ```
    Query.css("#modal")
    |> Query.visible(true)

    Query.css("#modal")
    |> Query.visible(false)
    ```
  """
  def visible(query, value) do
    update_condition(query, :visible, value)
  end

  @doc """
  Updates a query's `selected` option.

  ## Examples

    ```
    Query.css("#select-dropdown")
    |> Query.selected(true)

    Query.css("#select-dropdown")
    |> Query.selected(false)
    ```
  """
  def selected(query, value) do
    update_condition(query, :selected, value)
  end

  @doc """
  Updates a query's `count` option.

  ## Example

    ```
    Query.css(".names > li")
    |> Query.count(2)
    ```
  """
  def count(query, value) do
    update_condition(query, :count, value)
  end

  @doc """
  Updates a query's `at` option.

  ## Example

    ```
    Query.css(".names")
    |> Query.at(3)
    ```
  """
  def at(query, value) do
    update_condition(query, :at, value)
  end

  def validate(query) do
    cond do
      query.conditions[:minimum] > query.conditions[:maximum] ->
        {:error, :min_max}

      Query.visible?(query) != true && Query.inner_text(query) ->
        {:error, :cannot_set_text_with_invisible_elements}

      true ->
        {:ok, query}
    end
  end

  @doc """
  Compiles a query into CSS or xpath so its ready to be sent to the driver

      iex> Wallaby.Query.compile Wallaby.Query.text("my text")
      {:xpath, ".//*[contains(normalize-space(text()), \\"my text\\")]"}
      iex> Wallaby.Query.compile Wallaby.Query.css("#some-id")
      {:css, "#some-id"}
  """
  @spec compile(t) :: compiled
  def compile(%{method: :css, selector: selector}), do: {:css, selector}
  def compile(%{method: :xpath, selector: selector}), do: {:xpath, selector}
  def compile(%{method: :link, selector: selector}), do: {:xpath, XPath.link(selector)}
  def compile(%{method: :button, selector: selector}), do: {:xpath, XPath.button(selector)}

  def compile(%{method: :fillable_field, selector: selector}),
    do: {:xpath, XPath.fillable_field(selector)}

  def compile(%{method: :checkbox, selector: selector}), do: {:xpath, XPath.checkbox(selector)}

  def compile(%{method: :radio_button, selector: selector}),
    do: {:xpath, XPath.radio_button(selector)}

  def compile(%{method: :option, selector: selector}), do: {:xpath, XPath.option(selector)}
  def compile(%{method: :select, selector: selector}), do: {:xpath, XPath.select(selector)}

  def compile(%{method: :file_field, selector: selector}),
    do: {:xpath, XPath.file_field(selector)}

  def compile(%{method: :text, selector: selector}), do: {:xpath, XPath.text(selector)}

  def compile(%{method: :attribute, selector: {name, value}}),
    do: {:xpath, XPath.attribute(name, value)}

  def visible?(%Query{conditions: conditions}) do
    Keyword.get(conditions, :visible)
  end

  def selected?(%Query{conditions: conditions}) do
    Keyword.get(conditions, :selected)
  end

  def count(%Query{conditions: conditions}) do
    Keyword.get(conditions, :count)
  end

  def at_number(%Query{conditions: conditions}) do
    Keyword.get(conditions, :at)
  end

  def inner_text(%Query{conditions: conditions}) do
    Keyword.get(conditions, :text)
  end

  def result(query) do
    if specific_element_requested(query) do
      [element] = query.result
      element
    else
      query.result
    end
  end

  def specific_element_requested(query) do
    count(query) == 1 || at_number(query) != :all
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
    |> add_selected
    |> add_at
  end

  defp add_visibility(opts) do
    Keyword.put_new(opts, :visible, true)
  end

  defp add_selected(opts) do
    Keyword.put_new(opts, :selected, :any)
  end

  defp add_text(opts) do
    Keyword.put_new(opts, :text, nil)
  end

  defp add_count(opts) do
    if opts[:count] == nil && opts[:minimum] == nil && opts[:maximum] == nil do
      Keyword.put(opts, :count, 1)
    else
      opts
      |> Keyword.put_new(:count, opts[:count])
      |> Keyword.put_new(:minimum, opts[:minimum])
      |> Keyword.put_new(:maximum, opts[:maximum])
    end
  end

  defp add_at(opts) do
    Keyword.put_new(opts, :at, :all)
  end

  defp update_condition(%Query{conditions: conditions} = query, key, value) do
    updated_conditions = Keyword.put(conditions, key, value)
    %Query{query | conditions: updated_conditions}
  end
end
