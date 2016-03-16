defmodule Wallaby.DSL.Navigation do
  alias Wallaby.Session
  alias Wallaby.XPath
  alias Wallaby.DSL.Actions

  def visit(session, path) do
    Session.request(:post, "#{session.base_url}session/#{session.id}/url", %{url: request_url(path)})
    session
  end

  def click_link(session, link) do
    Wallaby.DSL.Finders.find(session, {:xpath, XPath.link(link)})
    |> Actions.click
    session
  end

  defp request_url(url), do: (Application.get_env(:wallaby, :base_url) || "") <> url
end
