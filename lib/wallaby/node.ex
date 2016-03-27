defmodule Wallaby.Node do
  defstruct [:session, :id]

  alias __MODULE__
  alias Wallaby.Driver
  alias Wallaby.Session

  import Wallaby.XPath

  def find(locator, query, opts \\ []) do
    retry fn ->
      locator
      |> Driver.find_elements(query)
      |> assert_element_count(Keyword.get(opts, :count, 1))
    end
  end

  def all(locator, query) do
    locator
    |> Driver.find_elements(query)
  end

  def fill_in(session, query, with: value) when is_binary(value) do
    find(session, {:xpath, fillable_field(query)})
    |> fill_in(with: value)
  end

  def fill_in(%Node{session: session}=node, with: value) when is_binary(value) do
    node
    |> Driver.set_value(value)
    session
  end

  def clear(session, query) when is_binary(query) do
    find(session, {:xpath, fillable_field(query)})
    |> clear()
  end

  def clear(locator) do
    Driver.clear(locator)
  end

  def choose(%Session{}=session, query) when is_binary(query) do
    find(session, {:xpath, radio_button(query)})
    |> click
  end

  def choose(%Node{}=node) do
    click(node)
  end

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

  def click(session, query) do
    find(session, query)
    |> click
  end

  def click(locator) do
    Driver.click(locator)
  end

  def text(node) do
    Driver.text(node)
  end

  def attr(node, name) do
    Driver.attribute(node, name)
  end

  def selected(node) do
    Driver.selected(node)
  end

  def has_value?(%Node{}=node, value) do
    attr(node, "value") == value
  end

  def has_content?(%Node{}=node, text) when is_binary(text) do
    text(node) == text
  end

  def checked?(%Node{}=node) do
    selected(node) == true
  end

  defp assert_element_count(elements, count) when is_list(elements) do
    case elements do
      elements when length(elements) > 0 and count == :any -> elements
      [element] when length(elements) == count -> element
      elements when length(elements) == count -> elements
      [] -> raise Wallaby.ElementNotFound, message: "Could not find element"
      elements -> raise Wallaby.AmbiguousMatch, message: "Ambiguous match, found #{length(elements)}"
    end
  end

  defp retry(find_fn, start_time \\ :erlang.monotonic_time(:milli_seconds)) do
    try do
      find_fn.()
    rescue
      e in [Wallaby.ElementNotFound, Wallaby.AmbiguousMatch] ->
        current_time = :erlang.monotonic_time(:milli_seconds)
        if current_time - start_time < max_wait_time do
          :timer.sleep(25)
          retry(find_fn, start_time)
        else
          raise e
        end
    end
  end

  defp max_wait_time do
    Application.get_env(:wallaby, :max_wait_time)
  end
end
