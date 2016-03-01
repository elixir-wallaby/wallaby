defmodule Wallaby.DSL.Navigation do
  alias Wallaby.Session

  def visit(%{id: session_id, base_url: base_url} = session, url) do
    Session.request(:post, "#{base_url}session/#{session_id}/url", %{url: url})
    session
  end

  # def click(%{id: session_id, base_url: base_url}, link_or_button) do
  #
  # end
end

