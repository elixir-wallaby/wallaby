defprotocol Wallaby.Session do
  # @fallback_to_any true

  def visit(session, url)

  def page_source(session)

  def click(session, link_or_button)

  def find(session, selector)

  def all(session, selector)
end

