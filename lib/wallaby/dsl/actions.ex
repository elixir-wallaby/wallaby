defmodule Wallaby.DSL.Actions do
  alias Wallaby.Session
  alias Wallaby.Node
  import Wallaby.DSL.Finders, only: [find: 2]
  import Wallaby.XPath

  def fill_in(session, query, with: value) when is_binary(value) do
    find(session, {:xpath, fillable_field(query)})
    |> fill_in(with: value)
  end
  def fill_in(%Node{session: session, id: id}, with: value) when is_binary(value) do
    Session.request(
      :post,
      "#{session.base_url}session/#{session.id}/element/#{id}/value",
      %{value: [value]}
    )
  end

  def clear(session, query) when is_binary(query) do
    find(session, {:xpath, fillable_field(query)})
    |> clear()
  end
  def clear(%Node{session: session, id: id}) do
    Session.request(:post, "#{session.base_url}session/#{session.id}/element/#{id}/clear")
  end

  def choose(%Session{}=session, query) when is_binary(query) do
    find(session, {:xpath, radio_button(query)})
    |> click
  end
  def choose(%Node{}=node) do
    click(node)
  end

  def click(session, query) do
    find(session, query)
  end
  def click(%Node{session: session, id: id}) do
    Session.request(:post, "#{session.base_url}session/#{session.id}/element/#{id}/click")
  end
end
