defmodule Wallaby.DSL.Finders do
  alias Wallaby.Session

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
end
