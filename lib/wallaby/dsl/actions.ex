defmodule Wallaby.DSL.Actions do
  # alias Wallaby.Session
  import Wallaby.DSL.Finders, only: [find: 2]

  def fill_in(session, query, with: value) do
    find(session, query)
  end
end
