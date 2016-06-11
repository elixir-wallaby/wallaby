defmodule Wallaby.Node.Query do
  @doc """
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
  def find_element(parent, {:fillable_field, query}, opts) do
    result =
      parent
      |> Driver.find_elements({:xpath, XPath.fillable_field(query)})
      |> assert_visibility(Keyword.get(opts, :visible, true))
      |> assert_element_count(Keyword.get(opts, :count, 1))

    case result do
      {:ok, field} ->
        field
      {:error, _error, elements} ->
        parent
        |> check_for_bad_labels(query)
        |> handle_error(elements, parent, query, opts)
    end
  end

  def find_element(parent, query, opts \\ []) do
    result =
      retry fn ->
        parent
        |> Driver.find_elements(build_query(query))
        |> assert_visibility(Keyword.get(opts, :visible, true))
        |> assert_element_count(Keyword.get(opts, :count, 1))
      end

    case result do
      {:ok, elements}       -> elements
      {:error, e, elements} -> handle_error(e, elements, parent, query, opts)
    end
  end

  def find_elements(parent, query, opts \\ []) do
    result =
      parent
      |> Driver.find_elements(build_query(query))
      |> assert_visibility(Keyword.get(opts, :visible, true))

    case result do
      {:ok, elements}       -> elements
      {:error, e, elements} -> handle_error(e, elements, parent, query, opts)
    end
  end

  def check_for_bad_labels(parent, query) do
    label =
      parent
      |> Driver.find_elements(build_query("label"))
      |> Enum.find(&bad_label?(&1, query))

    cond do
      label -> :label_with_no_for
      true  -> :not_found
    end
  end

  def bad_label?(node, query) do
    Node.attr(node, "for") == nil && Node.text(node) == query
  end

  defp assert_visibility(elements, visible) when is_list(elements) do
    cond do
      Enum.all?(elements, &(Node.visible?(&1) == visible)) -> {:ok, elements}
      true -> {:error, :not_visible, elements}
    end
  end

  defp assert_element_count({:ok, elements}, count) when is_list(elements) do
    assert_count(elements, count)
  end
  defp assert_element_count(error, _) do
    error
  end

  defp assert_count(elements, :any) when length(elements) > 0 do
    {:ok, elements}
  end
  defp assert_count([element], 1) do
    {:ok, element}
  end
  defp assert_count(elements, count) when length(elements) == count do
    {:ok, elements}
  end
  defp assert_count(elements, 0) when length(elements) > 0 do
    {:error, :found, elements}
  end
  defp assert_count([], _) do
    {:error, :not_found, []}
  end
  defp assert_count(elements, _) do
    {:error, :ambiguous, elements}
  end

  defp handle_error(:not_found, _, parent, query, opts) do
    raise Wallaby.ElementNotFound, build_query(query)
  end
  defp handle_error(:ambiguous, elements, parent, query, opts) do
    raise Wallaby.AmbiguousMatch, message: "Ambiguous match, found #{length(elements)}"
  end
  defp handle_error(:found, _, parent, query, opts) do
    raise Wallaby.ElementFound, build_query(query)
  end
  defp handle_error(:not_visible, _, parent, query, opts) do
    raise Wallaby.InvisibleElement, build_query(query)
  end
  defp handle_error(:label_with_no_for, _, parent, query, opts) do
    raise Wallaby.BadHTML, {:label_with_no_for, query}
  end

  defp retry(find_fn, start_time \\ :erlang.monotonic_time(:milli_seconds)) do
    case find_fn.() do
      {:ok, elements}       -> {:ok, elements}
      {:error, e, elements} ->
        cond do
          max_time_exceeded?(start_time) -> retry(find_fn, start_time)
          true                           -> {:error, e, elements}
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
