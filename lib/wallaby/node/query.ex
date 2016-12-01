defmodule Wallaby.Node.Query do
  @moduledoc ~S"""
  Provides the query DSL.

  Queries are used to locate and retrieve DOM nodes. The standard method for
  querying is css selectors:

  ```
  visit("/page.html")
  |> find("#main-page .dashboard")
  ```

  If more complex querying is needed then its possible to use XPath:

  ```
  find(page, {:xpath, "//input"})
  ```

  By default finders only work with elements that would be visible to a real
  user.

  ## Scoping

  Finders can also be chained together to provide scoping:

  ```
  visit("/page.html")
  |> find(".users")
  |> find(".user", count: 3)
  |> List.first
  |> find(".user-name")
  ```

  ## Form elements

  There are several custom finders for locating form elements. Each of these allows
  finding by their name, id text, or label text. This allows for more robust querying
  and decouples the query from presentation selectors like css classes.

  ## Query Options

  All of the query operations accept the following options:

    * `:count` - The number of elements that should be found (default: 1).
    * `:visible` - Determines if the query should return only visible elements (default: true).
    * `:text` - Text that should be found inside the element.
  """

  alias Wallaby.{Node, Session}
  alias Wallaby.Phantom.Driver
  alias Wallaby.XPath
  alias __MODULE__

  defstruct [
    query: nil,
    parent: nil,
    locator: nil,
    result: nil,
    conditions: [],
    errors: []
  ]

  @default_max_wait_time 3_000

  @type t :: %__MODULE__{
    parent: parent,
    locator: locator,
    conditions: opts,
    result: result,
    errors: errors,
  }

  @type parent :: Wallaby.Node.t | Wallaby.Session.t
  @type locator :: String.t | {atom(), String.t}
  @type query :: {atom(), String.t}
  @type opts :: list()
  @type result :: list(Node.t) | Node.t
  @type errors :: list()

  @doc """
  Builds a query struct to send to webdriver.
  """
  @spec build_query(parent, locator, opts) :: t

  def build_query(parent, locator, opts) do
    %__MODULE__{
      parent: parent,
      locator: locator,
      query: locator |> build_locator,
      conditions: build_conditions(opts),
    }
  end

  @doc """
  Finds a specific DOM node on the page based on a css selector. Blocks until
  it either finds the node or until the max time is reached. By default only
  1 node is expected to match the query. If more nodes are present then a
  count can be specified. By default only nodes that are visible on the page
  are returned.

  Selections can be scoped by providing a Node as the locator for the query.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec find(parent, locator, opts) :: result

  def find(parent, locator, opts) when is_binary(locator) do
    find(parent, {:css, locator}, opts)
  end

  def find(parent, selector, opts) do
    case find_element(parent, selector, opts) do
      {:ok, elements} ->
        elements
      {:error, query} ->
        handle_error(query)
    end
  end

  @doc """
  Finds all of the DOM nodes that match the css selector. If no elements are
  found then an empty list is immediately returned.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec all(parent, locator, opts) :: list(Node.t)

  def all(parent, locator, opts) when is_binary(locator) do
    all(parent, {:css, locator}, opts)
  end

  def all(parent, selector, opts) do
    case find_elements(parent, selector, opts) do
      {:ok, elements} ->
        elements
      {:error, query} ->
        handle_error(query)
    end
  end

  @doc """
  Locates a text field or textarea by its id, name, placeholder, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec fillable_field(parent, locator, opts) :: result

  def fillable_field(parent, locator, opts) do
    find_field(parent, {:fillable_field, locator}, opts)
  end

  @doc """
  Locates a radio button by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec radio_button(parent, locator, opts) :: result

  def radio_button(parent, locator, opts) do
    find_field(parent, {:radio_button, locator}, opts)
  end

  @doc """
  Finds a checkbox field by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec checkbox(parent, locator, opts) :: result

  def checkbox(parent, locator, opts) do
    find_field(parent, {:checkbox, locator}, opts)
  end

  @doc """
  Finds a select field by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec select(parent, locator, opts) :: result

  def select(parent, locator, opts) do
    find_field(parent, {:select, locator}, opts)
  end

  @doc """
  Finds an option field by its option text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec option(parent, locator, opts) :: result

  def option(parent, locator, opts) do
    find(parent, {:option, locator}, opts)
  end

  @doc """
  Finds a button by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec button(parent, locator, opts) :: result

  def button(parent, locator, opts) do
    find_field(parent, {:button, locator}, opts)
  end

  @doc """
  Finds a link field by its id, name, or text. If the link contains an image
  then it can find the link by the image's alt text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec link(parent, locator, opts) :: result

  def link(parent, locator, opts) do
    find(parent, {:link, locator}, opts)
  end

  @doc """
  Finds a field field by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec file_field(parent, locator, opts) :: result

  def file_field(parent, locator, opts) do
    find_field(parent, {:file_field, locator}, opts)
  end

  defp find_field(parent, query, opts) do
    case find_element(parent, query, opts) do
      {:ok, elements} ->
        elements
      {:error, query} ->
        if not_found?(query) do
          query
          |> check_for_bad_html
          |> handle_error
        else
          query
          |> handle_error
        end
    end
  end

  defp not_found?(query) do
    query.errors
    |> Enum.any?(& &1 == :not_found)
  end

  defp find_element(parent, locator, opts) do
    query = build_query(parent, locator, opts)

    retry fn ->
      query
      |> Driver.find_elements
      |> assert_text
      |> assert_visibility
      |> assert_count
    end
  end

  defp find_elements(parent, locator, opts) do
    query = build_query(parent, locator, opts)

    retry fn ->
      query
      |> Driver.find_elements
      |> assert_text
      |> assert_visibility
    end
  end

  defp check_for_bad_html(%Query{locator: {:button, locator}}=query) do
    buttons =
      query.parent
      |> all("button", [])

    cond do
      Enum.any?(buttons, &(matching_text?(&1, locator))) ->
        add_error(query, :button_with_bad_type)
      true ->
        query
    end
  end
  defp check_for_bad_html(query) do
    check_for_bad_labels(query)
  end

  defp check_for_bad_labels(%Query{parent: parent, locator: {_, text}}=query) do
    labels =
      parent
      |> all("label", [])

    cond do
      Enum.any?(labels, &(missing_for?(&1) && matching_text?(&1, text))) ->
        add_error(query, :label_with_no_for)
      label=Enum.find(labels, &matching_text?(&1, text)) ->
        add_error(query, {:label_does_not_find_field, Node.attr(label, "for")})
      true  ->
        add_error(query, :not_found)
    end
  end

  defp missing_for?(node) do
    Node.attr(node, "for") == nil
  end

  defp matching_text?(node, locator) do
    Node.text(node) =~ ~r/#{Regex.escape(locator)}/
  end

  defp assert_text(%Query{result: nodes, conditions: opts}=query) do
    text = Keyword.get(opts, :text)

    if text do
      %Query{query | result: Enum.filter(nodes, &matching_text?(&1, text))}
    else
      query
    end
  end

  defp assert_visibility(%Query{result: nodes, conditions: opts}=query) do
    visible = Keyword.get(opts, :visible)

    cond do
      visible && Enum.all?(nodes, &(Node.visible?(&1))) ->
        query
      !visible && Enum.all?(nodes, &(!Node.visible?(&1))) ->
        query
      visible ->
        add_error(query, :not_visible)
      !visible ->
        add_error(query, :visible)
    end
  end

  defp assert_count(%Query{result: nodes, conditions: opts}=query) do
    count = Keyword.get(opts, :count)

    cond do
      count == 1    && length(nodes) == 1 -> %Query{query | result: hd(nodes)}
      count == :any && length(nodes) > 0  -> query
      count == length(nodes)              -> query
      count == 0    && length(nodes) > 0  -> add_error(query, :found)
      length(nodes) == 0                  -> add_error(query, :not_found)
      true                                -> add_error(query, :ambiguous)
    end
  end

  defp add_error(query, error) do
    %Query{query | errors: [error | query.errors]}
  end

  defp handle_error(query) do
    if Wallaby.screenshot_on_failure? do
      Session.take_screenshot(query.parent)
    end

    raise Wallaby.QueryError, query
  end

  defp retry(find_fn, start_time \\ :erlang.monotonic_time(:milli_seconds)) do
    query = find_fn.()

    cond do
      query.errors == [] ->
        {:ok, query.result}
      true ->
        cond do
          max_time_exceeded?(start_time) -> retry(find_fn, start_time)
          true                           -> {:error, query}
        end
    end
  end

  def max_time_exceeded?(start_time) do
    :erlang.monotonic_time(:milli_seconds) - start_time < max_wait_time
  end

  defp max_wait_time do
    Application.get_env(:wallaby, :max_wait_time, @default_max_wait_time)
  end

  defp build_locator({:css, query}), do: {:css, query}
  defp build_locator({:xpath, query}), do: {:xpath, query}
  defp build_locator({:link, query}), do: {:xpath, XPath.link(query)}
  defp build_locator({:button, query}), do: {:xpath, XPath.button(query)}
  defp build_locator({:fillable_field, query}), do: {:xpath, XPath.fillable_field(query)}
  defp build_locator({:checkbox, query}), do: {:xpath, XPath.checkbox(query)}
  defp build_locator({:radio_button, query}), do: {:xpath, XPath.radio_button(query)}
  defp build_locator({:option, query}), do: {:xpath, XPath.option(query)}
  defp build_locator({:select, query}), do: {:xpath, XPath.select(query)}
  defp build_locator({:file_field, query}), do: {:xpath, XPath.file_field(query)}

  defp build_conditions(conditions) do
    default_conditions
    |> Keyword.merge(conditions)
  end

  defp default_conditions do
    [
      visible: true,
      count: 1,
    ]
  end
end
