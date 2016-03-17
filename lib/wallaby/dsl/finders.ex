defmodule Wallaby.DSL.Finders do
  alias Wallaby.Session

  @default_max_wait_time 5_000

  def find(session, query) do
    case do_find_elements(session, to_params(query)) do
      [element] -> element
      [] -> raise Wallaby.ElementNotFound, message: "Could not find element"
      elements -> raise Wallaby.AmbiguousMatch, message: "Ambiguous match, found #{length(elements)}"
    end
  end

  def all(session, query) do
    do_find_elements(session, to_params(query))
  end

  def wait_until_visible(session, query, opts \\ [])
  def wait_until_visible(session, query, [{:count, count} | _] = _opts) do
    retry fn ->
      case all(session, query) do
        elements when length(elements) == count -> elements
        _ -> raise Wallaby.ElementNotFound, message: "Could not find #{count} elements"
      end
    end
  end
  def wait_until_visible(session, query, _opts), do: retry fn -> find(session, query) end

  defp to_params({:xpath, xpath}) do
    %{using: "xpath", value: xpath}
  end
  defp to_params(css_selector) do
    %{using: "css selector", value: css_selector}
  end

  defp do_find_elements(%{id: session_id, base_url: base_url} = session, params) do
    response = Session.request(:post, "#{base_url}session/#{session_id}/elements", params)

    Enum.map response["value"], fn %{"ELEMENT" => id} ->
      %Wallaby.Node{id: id, session: session}
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
