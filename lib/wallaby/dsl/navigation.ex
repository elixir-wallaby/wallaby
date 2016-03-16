defmodule Wallaby.DSL.Navigation do
  alias Wallaby.Session
  alias Wallaby.XPath
  alias Wallaby.DSL.Actions

  def visit(session, url) do
    Session.request(:post, "#{session.base_url}session/#{session.id}/url", %{url: url})
    session
  end

  def click_link(session, link) do
    Wallaby.DSL.Finders.find(session, {:xpath, XPath.link(link)})
    |> Actions.click
    session
  end
end
