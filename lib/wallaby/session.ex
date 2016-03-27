defmodule Wallaby.Session do
  defstruct [:id, :base_url, :server]

  alias Wallaby.Driver
  alias Wallaby.Node
  alias Wallaby.XPath

  def visit(session, path) do
    Driver.visit(session, request_url(path))
    session
  end

  def click_link(session, link) do
    Node.find(session, {:xpath, XPath.link(link)})
    |> Node.click
    session
  end

  def take_screenshot(%Node{session: session}=node) do
    take_screenshot(session)
    node
  end

  def take_screenshot(session) do
    path = Driver.take_screenshot(session)
    %{session: session, path: path}
  end

  def set_window_size(session, width, height) do
    Driver.set_window_size(session, width, height)
    session
  end

  def get_window_size(session) do
    Driver.get_window_size(session)
  end

  defp request_url(url), do: (Application.get_env(:wallaby, :base_url) || "") <> url
end
