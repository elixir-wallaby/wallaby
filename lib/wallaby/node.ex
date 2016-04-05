defmodule Wallaby.Node do
  @moduledoc """
  Common functionality for interacting with DOM nodes.

  Nodes can be found by executing css queries against a page:

  ```
  visit("/page.html")
  |> find("#main-page .dashboard")
  ```

  Finders can also be chained together to provide scoping:

  ```
  visit("/page.html")
  |> find(".users")
  |> find(".user", count: 3)
  |> List.first
  |> find(".user-name")
  |> text
  ```
  """

  defstruct [:session, :id]

  @type t :: %__MODULE__{
    session: Session.t,
    id: String.t
  }

  @type locator :: Session.t | t
  @type query :: String.t | {:xpath, String.t}

  alias __MODULE__
  alias Wallaby.Driver
  alias Wallaby.Session

  import Wallaby.XPath

  @default_max_wait_time 3_000

  @doc """
  Finds a specific DOM node on the page based on a css selector. Blocks until
  it either finds the node or until the max time is reached. By default only
  1 node is expected to match the query. If more nodes are present then a
  count can be specified. By default only nodes that are visible on the page
  are returned.

  Selections can be scoped by providing a Node as the locator for the query.
  """
  @spec find(locator, query, Keyword.t) :: t | list(t)

  def find(locator, query, opts \\ []) do
    retry fn ->
      locator
      |> Driver.find_elements(query)
      |> assert_visibility(Keyword.get(opts, :visible, true))
      |> assert_element_count(Keyword.get(opts, :count, 1))
    end
  end

  @doc """
  Finds all of the DOM nodes that match the css selector. If no elements are
  found then an empty list is immediately returned.
  """
  @spec all(locator, query) :: list(t)

  def all(locator, query) do
    locator
    |> Driver.find_elements(query)
  end

  @doc """
  Fills in a "fillable" node with text. Input nodes are looked up by id, label text,
  or name. The specific node can also be passed in directly.
  """
  @spec fill_in(locator, query, [with: String.t]) :: Session.t
  @spec fill_in(Node.t, [with: String.t]) :: Session.t

  def fill_in(session, query, with: value) when is_binary(value) do
    find(session, {:xpath, fillable_field(query)})
    |> fill_in(with: value)
  end

  def fill_in(%Node{session: session}=node, with: value) when is_binary(value) do
    clear(node)
    Driver.set_value(node, value)
    session
  end

  @doc """
  Selects an option from a select box. Searches for the select box by id, name or label,
  then finds the option by visible text.

  The specific node for the select box can also be passed in directly.
  """
  @spec select(locator, String.t, [option: query]) :: Session.t
  @spec select(Node.t, [option: query]) :: Session.t

  def select(session, selector, option: query) do
    find(session, {:xpath, select_box(selector)})
    |> find({:xpath, option_for(query)})
    |> click

    session
  end

  def select(%Node{session: session}=node, option: query) do
    node
    |> find({:xpath, option_for(query)})
    |> click

    session
  end

  @doc """
  Clears an input field. Input nodes are looked up by id, label text, or name.
  The node can also be passed in directly.
  """
  @spec clear(Session.t, query) :: Session.t
  @spec clear(Node.t) :: Session.t

  def clear(session, query) when is_binary(query) do
    find(session, {:xpath, fillable_field(query)})
    |> clear()
  end

  def clear(locator) do
    Driver.clear(locator)
  end

  @doc """
  Chooses a radio button.
  """
  @spec choose(Session.t, query) :: Session.t
  @spec choose(Node.t) :: Session.t

  def choose(%Session{}=session, query) when is_binary(query) do
    find(session, {:xpath, radio_button(query)})
    |> click
  end

  def choose(%Node{}=node) do
    click(node)
  end

  @doc """
  Marks a checkbox as "checked".
  """
  @spec check(Session.t, query) :: Session.t
  @spec check(Node.t) :: Node.t

  def check(%Node{}=node) do
    unless checked?(node) do
      click(node)
    end
    node
  end

  def check(%Session{}=session, query) do
    find(session, {:xpath, checkbox(query)})
    |> check
    session
  end

  @doc """
  Unchecks a checkbox.
  """
  @spec uncheck(Session.t, query) :: Session.t
  @spec uncheck(t) :: t

  def uncheck(%Node{}=node) do
    if checked?(node) do
      click(node)
    end
    node
  end

  def uncheck(%Session{}=session, query) do
    find(session, {:xpath, checkbox(query)})
    |> uncheck
    session
  end

  @doc """
  Clicks a node.
  """
  @spec click(Session.t, query) :: Session.t
  @spec click(t) :: Session.t

  def click(session, query) do
    find(session, query)
    |> click
  end

  def click(locator) do
    Driver.click(locator)
  end

  @doc """
  Gets the Node's text value.
  """
  @spec text(t) :: String.t

  def text(node) do
    Driver.text(node)
  end

  @doc """
  Gets the value of the nodes attribute.
  """
  @spec attr(t, String.t) :: String.t

  def attr(node, name) do
    Driver.attribute(node, name)
  end

  @doc """
  Gets the selected value of the element.

  For Checkboxes and Radio buttons it returns the selected option.
  """
  @spec selected(t) :: any()

  def selected(node) do
    Driver.selected(node)
  end

  @doc """
  Matches the Node's value with the provided value.
  """
  @spec has_value?(t, any()) :: boolean()

  def has_value?(%Node{}=node, value) do
    attr(node, "value") == value
  end

  @doc """
  Matches the Node's content with the provided text and raises if not found
  """
  @spec assert_text(t, String.t) :: boolean()

  def assert_text(%Node{}=node, text) when is_binary(text) do
    retry fn ->
      regex_results = Regex.run(~r/#{text}/, text(node))
      if regex_results |> is_nil do
        raise Wallaby.ExpectationNotMet, "Text '#{text}' not found"
      end
      true
    end
  end

  @doc """
  Matches the Node's content with the provided text
  """
  @spec has_text?(t, String.t) :: boolean()

  def has_text?(%Node{}=node, text) when is_binary(text) do
    try do
      assert_text(node, text)
    rescue
      e in Wallaby.ExpectationNotMet -> false
    end
  end

  @doc """
  Searches for CSS on the page.
  """
  @spec has_css?(locator, String.t) :: boolean()

  def has_css?(locator, css) when is_binary(css) do
    find(locator, css, [count: :any])
    |> Enum.any?
  end

  @doc """
  Searches for css that should not be on the page
  """
  @spec has_no_css?(locator, String.t) :: boolean()

  def has_no_css?(locator, css) when is_binary(css) do
    find(locator, css, count: 0)
    |> Enum.empty?
  end

  @doc """
  Checks if the node has been selected.
  """
  @spec checked?(t) :: boolean()

  def checked?(%Node{}=node) do
    selected(node) == true
  end

  @doc """
  Checks if the node has been selected. Alias for checked?(node)
  """
  @spec selected?(t) :: boolean()

  def selected?(%Node{}=node) do
    checked?(node)
  end

  @doc """
  Checks if the node is visible on the page
  """
  @spec visible?(t) :: boolean()

  def visible?(%Node{}=node) do
    Driver.displayed(node)
  end

  defp assert_element_count(elements, count) when is_list(elements) do
    case elements do
      elements when length(elements) > 0 and count == :any -> elements
      [element] when length(elements) == count -> element
      elements when length(elements) == count -> elements
      elements when length(elements) > 0 and count == 0 -> raise Wallaby.ExpectationNotMet, message: "Element was found"
      [] -> raise Wallaby.ElementNotFound, message: "Could not find element"
      elements -> raise Wallaby.AmbiguousMatch, message: "Ambiguous match, found #{length(elements)}"
    end
  end

  defp assert_visibility(elements, visible) when is_list(elements) do
    if Enum.all?(elements, &(visible?(&1) == visible)) do
      elements
    else
      raise Wallaby.ElementNotFound, message: "Could not find element"
    end
  end

  defp retry(find_fn, start_time \\ :erlang.monotonic_time(:milli_seconds)) do
    try do
      find_fn.()
    rescue
      e in [Wallaby.ElementNotFound, Wallaby.AmbiguousMatch, Wallaby.ExpectationNotMet] ->
        current_time = :erlang.monotonic_time(:milli_seconds)
        if (current_time - start_time) < max_wait_time do
          :timer.sleep(25)
          retry(find_fn, start_time)
        else
          raise e
        end
    end
  end

  defp max_wait_time do
    Application.get_env(:wallaby, :max_wait_time, @default_max_wait_time)
  end
end
