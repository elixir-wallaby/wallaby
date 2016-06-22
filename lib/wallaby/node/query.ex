defmodule Wallaby.Node.Query do
  @moduledoc """
  Queries are used to find things on the page.
  If a dom node has already been found then any future queries will
  be nested under the first query.

  Querying is not lazy. Which means that once we've done a query we're now talking
  about a Node.

  Node's have actions associated with them. You can access values from that node.

  In some cases queries allow you to interact with elements by using real world
  text. For instance if you want to click a button you just say `click_button('Enter the form')`

  This allows you to construct much more readable tests.

  However, it presents a problem in the code. Each of those queries has to be
  done with xpath. In general thats not a big deal though.

  All queries need to be done through the query domain though. That way we can
  abstract out the query engine itself.

  The query engine is also the right place to handle all of the error handling
  that we want to do. It also means that we need fewer assertions and then we can
  derive the rest of the `has_*` matchers from them.

  This could probably be managed with a protocol as well.

  By default all of the matchers and finders should only work with visible
  elements.
  """

  alias Wallaby.{Node, Driver}
  alias Wallaby.XPath

  @default_max_wait_time 3_000

  @doc """
  Finds a specific DOM node on the page based on a css selector. Blocks until
  it either finds the node or until the max time is reached. By default only
  1 node is expected to match the query. If more nodes are present then a
  count can be specified. By default only nodes that are visible on the page
  are returned.

  Selections can be scoped by providing a Node as the locator for the query.
  """
  def find(parent, selector, opts \\ []) do
    case find_element(parent, selector, opts) do
      {:ok, elements} ->
        elements
      {:error, e} ->
        handle_error(e)
    end
  end

  def all(parent, selector, opts \\ []) do
    case find_elements(parent, selector, opts) do
      {:ok, elements} ->
        elements
      {:error, e} ->
        handle_error(e)
    end
  end

  def fillable_field(parent, locator, opts \\ []) do
    find_field(parent, {:fillable_field, locator}, opts)
  end

  def radio_button(parent, locator, opts \\ []) do
    find_field(parent, {:radio_button, locator}, opts)
  end

  def checkbox(parent, locator, opts \\ []) do
    find_field(parent, {:checkbox, locator}, opts)
  end

  def select(parent, locator, opts \\ []) do
    find_field(parent, {:select, locator}, opts)
  end

  def option(parent, locator, opts \\ []) do
    find(parent, {:option, locator}, opts)
  end

  def button(parent, locator, opts \\ []) do
    find(parent, {:button, locator}, opts)
  end

  def link(parent, locator, opts \\ []) do
    find(parent, {:link, locator}, opts)
  end

  def find_field(parent, query, opts) do
    case find_element(parent, query, opts) do
      {:ok, elements} ->
        elements
      {:error, {:not_found, _}} ->
        parent
        |> check_for_bad_labels(query)
        |> handle_error
      {:error, e} ->
        handle_error(e)
    end
  end

  defp find_element(parent, locator, opts) do
    query = build_query(locator)

    retry fn ->
      parent
      |> Driver.find_elements(query)
      |> assert_visibility(query, Keyword.get(opts, :visible, true))
      |> assert_element_count(query, Keyword.get(opts, :count, 1))
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
      |> all("label")

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
      Enum.all?(elements, &(Node.visible?(&1) == visible)) ->
        {:ok, elements}
      true ->
        {:error, {:not_visible, query}}
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

  defp handle_error({:not_found, locator}) do
    raise Wallaby.ElementNotFound, locator
  end
  defp handle_error({:ambiguous, locator, elements, count}) do
    raise Wallaby.AmbiguousMatch, {locator, elements, count}
  end
  defp handle_error({:found, locator}) do
    raise Wallaby.ElementFound, locator
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
  defp build_query({:field, query}), do: {:xpath, XPath.field(query)}
  defp build_query(query) when is_binary(query), do: {:css, query}
end
