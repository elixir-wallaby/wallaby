defmodule Wallaby.DSL.Navigation do
  alias Wallaby.Session
  alias Wallaby.XPath
  alias Wallaby.Driver
  alias Wallaby.DSL.Actions

  def visit(session, path) do
    Driver.visit(session, request_url(path))
  end

  def click_link(session, link) do
    Wallaby.DSL.Finders.find(session, {:xpath, XPath.link(link)})
    |> Actions.click
    session
  end

  defp request_url(url), do: (Application.get_env(:wallaby, :base_url) || "") <> url
end
