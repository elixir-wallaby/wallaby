defmodule Wallaby.DSL.Attributes do
  alias Wallaby.Session

  def text(node) do
    response = Session.request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/text")
    response["value"]
  end

  def attr(node, name) do
    response = Session.request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/attribute/#{name}")
    response["value"]
  end

  def selected(node) do
    response = Session.request(:get, "#{node.session.base_url}session/#{node.session.id}/element/#{node.id}/selected")
    response["value"]
  end
end
