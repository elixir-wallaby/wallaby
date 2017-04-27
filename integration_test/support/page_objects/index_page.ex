defmodule Wallaby.Integration.PageObjects.IndexPage do
  use Wallaby.DSL

  def visit(session) do
    session
    |> visit("")
  end

  def click_page_1_link(session) do
    session
    |> click_link("Page 1")
  end

  def ensure_page_loaded(session) do
    session
    |> Browser.find(Query.css(".index-page"))

    session
  end
end
