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

  defp do_find_elements(%{id: session_id, base_url: base_url}, params) do
    response = Session.request(:post, "#{base_url}session/#{session_id}/elements", params)

    Enum.map response["value"], fn %{"ELEMENT" => id} ->
      %Wallaby.Node{id: id}
    end
  end
end

# def page_source(%{id: session_id, base_url: base_url}) do
#   request(:get, "#{base_url}session/#{session_id}/source")
# end
#
# def attribute_value(element, attribute_name) do
#   element_id = get_element_id(element)
#   session_id = Hound.current_session_id
#   make_req(:get, "session/#{session_id}/element/#{element_id}/attribute/#{attribute_name}")
# end
