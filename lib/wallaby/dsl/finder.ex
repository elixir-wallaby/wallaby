defmodule Wallaby.DSL.Finder do
  alias Wallaby.Session

  def find(%{id: session_id, base_url: base_url}, selector) do
    params = %{using: "css selector", value: selector}

    response = Session.request(:post, "#{base_url}session/#{session_id}/element", params)

    case response["value"] do
      %{"ELEMENT" => id} -> %Wallaby.Node{id: id}
      _ -> nil
    end
  end

  def all(%{id: session_id, base_url: base_url}, selector) do
    params = %{using: "css selector", value: selector}

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
