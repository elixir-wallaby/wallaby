defmodule Wallaby.Integration.Pages.IndexPage do
  use Wallaby.DSL

  def visit(session) do
    session
    |> visit("")
  end

  def click_page_1_link(session) do
    session
    |> click(Query.link("Page 1"))
  end

  def ensure_page_loaded(session) do
    session
    |> Browser.find(Query.css(".index-page"))

    session
  end
end
