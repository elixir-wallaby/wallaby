defmodule Wallaby.DSL.Finders do
  alias Wallaby.Session
  alias Wallaby.Node
  alias Wallaby.Driver

  @default_max_wait_time 3_000

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

  defp assert_element_count(elements, count) when is_list(elements) do
    case elements do
      elements when length(elements) > 0 and count == :any -> elements
      [element] when length(elements) == count -> element
      elements when length(elements) == count -> elements
      [] -> raise Wallaby.ElementNotFound, message: "Could not find element"
      elements -> raise Wallaby.AmbiguousMatch, message: "Ambiguous match, found #{length(elements)}"
    end
  end

  defp retry(find_fn, max_wait_time \\ @default_max_wait_time, start_time \\ :erlang.monotonic_time(:milli_seconds)) do
    try do
      find_fn.()
    rescue
      e in [Wallaby.ElementNotFound, Wallaby.AmbiguousMatch] ->
        current_time = :erlang.monotonic_time(:milli_seconds)
        if current_time - start_time < max_wait_time do
          :timer.sleep(25)
          retry(find_fn, max_wait_time, start_time)
        else
          raise e
        end
    end
  end
end
