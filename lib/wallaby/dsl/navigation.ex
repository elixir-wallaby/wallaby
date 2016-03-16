defmodule Wallaby.DSL.Navigation do
  alias Wallaby.Session
  alias Wallaby.XPath

  def visit(session, url) do
    Session.request(:post, "#{session.base_url}session/#{session.id}/url", %{url: url})
    session
  end

  def click_link(session, link) do
    node = Wallaby.DSL.Finders.find(session, {:xpath, XPath.link(link)})
    Session.request(:post, "#{session.base_url}session/#{session.id}/element/#{node.id}/click")
    session
  end
end
