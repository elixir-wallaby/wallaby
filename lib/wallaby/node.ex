defmodule Wallaby.Node do
  @moduledoc """
  Common functionality for interacting with DOM nodes.
  """

  defstruct [:url, :session_url, :parent, :id, screenshots: []]

  @type url :: String.t
  @type query :: String.t
  @type locator :: Session.t | t
  @type t :: %__MODULE__{
    session_url: url,
    url: url,
    id: String.t,
    screenshots: list,
  }

  alias __MODULE__
  alias Wallaby.Phantom.Driver
  alias Wallaby.Session
  alias Wallaby.Node.Query

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

  def find(parent, query, opts \\ []) do
    Query.find(parent, query, opts)
  end

  @doc """
  Finds all of the DOM nodes that match the css selector. If no elements are
  found then an empty list is immediately returned.
  """
  @spec all(locator, query) :: list(t)

  def all(parent, query, opts \\ []) do
    Query.all(parent, query, opts)
  end

  @doc """
  Fills in the node with the supplied value
  """
  @spec fill_in(Node.t, [with: String.t]) :: Node.t

  def fill_in(%Node{}=node, with: value) when is_binary(value) do
    node
    |> clear
    |> Driver.set_value(value)

    node
  end

  @doc """
  Clears an input field. Input nodes are looked up by id, label text, or name.
  The node can also be passed in directly.
  """
  @spec clear(Node.t) :: Session.t

  def clear(node) do
    Driver.clear(node)
    node
  end

  @doc """
  Chooses a radio button.
  """
  @spec choose(Node.t) :: Node.t

  def choose(%Node{}=node) do
    click(node)
  end

  @doc """
  Marks a checkbox as "checked".
  """
  @spec check(Node.t) :: Node.t

  def check(%Node{}=node) do
    unless checked?(node) do
      click(node)
    end
    node
  end

  @doc """
  Unchecks a checkbox.
  """
  @spec uncheck(t) :: t

  def uncheck(%Node{}=node) do
    if checked?(node) do
      click(node)
    end
    node
  end

  @doc """
  Clicks a node.
  """
  @spec click(t) :: Session.t

  def click(node) do
    Driver.click(node)
    node
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
  @spec attr(t, String.t) :: String.t | nil

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
      _e in Wallaby.ExpectationNotMet -> false
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

  defp retry(find_fn, start_time \\ :erlang.monotonic_time(:milli_seconds)) do
    try do
      find_fn.()
    rescue
      e in [Wallaby.ExpectationNotMet] ->
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
