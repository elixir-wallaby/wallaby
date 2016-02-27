defmodule Wallaby.DSL.Navigation do
  alias Wallaby.Webdriver

  def visit(session, url) do
    Webdriver.post(session, "/url", %{url: url})
  end
end

