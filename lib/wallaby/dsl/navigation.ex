defmodule Wallaby.DSL.Navigation do
  alias Wallaby.Session

  def visit(session, url) do
    Session.request(:post, "#{session.base_url}session/#{session.id}/url", %{url: url})
    session
  end

  def click_link(session, link) do
    # this xpath is gracious ripped from capybara via
    # https://github.com/jnicklas/xpath/blob/master/lib/xpath/html.rb

    xpath = ".//a[./@href][(((./@id = '#{link}' or contains(normalize-space(string(.)), '#{link}')) or contains(./@title, '#{link}')) or .//img[contains(./@alt, '#{link}')])]"

    node = Wallaby.DSL.Finders.find(session, {:xpath, xpath})

    Session.request(:post, "#{session.base_url}session/#{session.id}/element/#{node.id}/click")
    session
  end
end

