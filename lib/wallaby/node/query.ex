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
  """

  alias Wallaby.{Node, Driver, Session}
  alias Wallaby.XPath

  @default_max_wait_time 3_000

  @type parent :: Wallaby.Node.t | Wallaby.Session.t
  @type locator :: String.t | {atom(), String.t}
  @type opts :: list()
  @type result :: list(Node.t) | Node.t

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
      {:error, e} ->
        cleanup(parent, e)
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
      {:error, e} ->
        cleanup(parent, e)
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
  Locates a radio button by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec radio_button(parent, locator, opts) :: result

  def radio_button(parent, locator, opts) do
    find_field(parent, {:radio_button, locator}, opts)
  end

  @doc """
  Finds a checkbox field by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec checkbox(parent, locator, opts) :: result

  def checkbox(parent, locator, opts) do
    find_field(parent, {:checkbox, locator}, opts)
  end

  @doc """
  Finds a select field by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec select(parent, locator, opts) :: result

  def select(parent, locator, opts) do
    find_field(parent, {:select, locator}, opts)
  end

  @doc """
  Finds an option field by its option text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec option(parent, locator, opts) :: result

  def option(parent, locator, opts) do
    find(parent, {:option, locator}, opts)
  end

  @doc """
  Finds a button by its id, name, or label text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec button(parent, locator, opts) :: result

  def button(parent, locator, opts) do
    find(parent, {:button, locator}, opts)
  end

  @doc """
  Finds a link field by its id, name, or text. If the link contains an image
  then it can find the link by the image's alt text.

  ## Options

  See the "Query Options" section in the module documentation
  """
  @spec link(parent, locator, opts) :: result

  def link(parent, locator, opts) do
    find(parent, {:link, locator}, opts)
  end

  defp find_field(parent, query, opts) do
    case find_element(parent, query, opts) do
      {:ok, elements} ->
        elements
      {:error, {:not_found, _}} ->
        error = check_for_bad_labels(parent, query)
        cleanup(parent, error)
      {:error, error} ->
        cleanup(parent, error)
    end
  end

  defp find_element(parent, locator, opts) do
    query = build_query(locator)

    retry fn ->
      parent
      |> Driver.find_elements(query)
      |> assert_visibility(locator, Keyword.get(opts, :visible, true))
      |> assert_element_count(locator, Keyword.get(opts, :count, 1))
    end
  end

  defp find_elements(parent, locator, opts) do
    query = build_query(locator)

    parent
    |> Driver.find_elements(query)
    |> assert_visibility(query, Keyword.get(opts, :visible, true))
  end

  defp check_for_bad_labels(parent, {_, locator}=query) do
    labels =
      parent
      |> all("label", [])

    cond do
      Enum.any?(labels, &(missing_for?(&1) && matching_text?(&1, locator))) ->
        {:label_with_no_for, query}
      label=Enum.find(labels, &matching_text?(&1, locator)) ->
        {:label_does_not_find_field, query, Node.attr(label, "for")}
      true  ->
        {:not_found, query}
    end
  end

  defp missing_for?(node) do
    Node.attr(node, "for") == nil
  end

  defp matching_text?(node, locator) do
    Node.text(node) == locator
  end

  defp assert_visibility(elements, query, visible) when is_list(elements) do
    cond do
      visible && Enum.all?(elements, &(Node.visible?(&1))) ->
        {:ok, elements}
      !visible && Enum.all?(elements, &(!Node.visible?(&1))) ->
        {:ok, elements}
      visible ->
        {:error, {:not_visible, query}}
      !visible ->
        {:error, {:visible, query}}
    end
  end

  defp assert_element_count({:ok, elements}, query, count) when is_list(elements) do
    assert_count(elements, query, count)
  end
  defp assert_element_count(error, _query, _) do
    error
  end

  defp assert_count(elements, _query, :any) when length(elements) > 0 do
    {:ok, elements}
  end
  defp assert_count([element], _query, 1) do
    {:ok, element}
  end
  defp assert_count(elements, _query, count) when length(elements) == count do
    {:ok, elements}
  end
  defp assert_count(elements, query, 0) when length(elements) > 0 do
    {:error, {:found, query}}
  end
  defp assert_count([], query, _) do
    {:error, {:not_found, query}}
  end
  defp assert_count(elements, query, count) do
    {:error, {:ambiguous, query, elements, count}}
  end

  defp cleanup(parent, error) do
    if Wallaby.screenshot_on_failure? do
      Session.take_screenshot(parent)
    end

    handle_error(error)
  end

  defp handle_error({:not_found, locator}) do
    raise Wallaby.ElementNotFound, locator
  end
  defp handle_error({:ambiguous, locator, elements, count}) do
    raise Wallaby.AmbiguousMatch, {locator, elements, count}
  end
  defp handle_error({:found, locator}) do
    raise Wallaby.ElementFound, locator
  end
  defp handle_error({:visible, locator}) do
    raise Wallaby.VisibleElement, locator
  end
  defp handle_error({:not_visible, locator}) do
    raise Wallaby.InvisibleElement, locator
  end
  defp handle_error({:label_with_no_for, locator}) do
    raise Wallaby.BadHTML, {:label_with_no_for, locator}
  end
  defp handle_error({:label_does_not_find_field, locator, for_text}) do
    raise Wallaby.BadHTML, {:label_does_not_find_field, locator, for_text}
  end

  defp retry(find_fn, start_time \\ :erlang.monotonic_time(:milli_seconds)) do
    case find_fn.() do
      {:ok, elements} ->
        {:ok, elements}
      {:error, e} ->
        cond do
          max_time_exceeded?(start_time) -> retry(find_fn, start_time)
          true                           -> {:error, e}
        end
    end
  end

  def max_time_exceeded?(start_time) do
    :erlang.monotonic_time(:milli_seconds) - start_time < max_wait_time
  end

  defp max_wait_time do
    Application.get_env(:wallaby, :max_wait_time, @default_max_wait_time)
  end

  defp build_query({:css, query}), do: {:css, query}
  defp build_query({:xpath, query}), do: {:xpath, query}
  defp build_query({:link, query}), do: {:xpath, XPath.link(query)}
  defp build_query({:button, query}), do: {:xpath, XPath.button(query)}
  defp build_query({:fillable_field, query}), do: {:xpath, XPath.fillable_field(query)}
  defp build_query({:checkbox, query}), do: {:xpath, XPath.checkbox(query)}
  defp build_query({:radio_button, query}), do: {:xpath, XPath.radio_button(query)}
  defp build_query({:option, query}), do: {:xpath, XPath.option(query)}
  defp build_query({:select, query}), do: {:xpath, XPath.select(query)}
end
