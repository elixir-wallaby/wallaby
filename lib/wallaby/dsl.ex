defmodule Wallaby.DSL do
  @moduledoc """
  Sets up the Wallaby DSL in a module.

  All functions in `Wallaby.Browser` are now accessible without a module name
  and `Wallaby.Browser`, `Wallaby.Element` and `Wallaby.Query` are all aliased.

  ## Example

  ```
  defmodule MyPage do
    use Wallaby.DSL

    @name_field Query.text_field("Name")
    @email_field Query.text_field("email")
    @save_button Query.button("Save")

    def register(session) do
      session
      |> visit("/registration.html")
      |> fill_in(@name_field, with: "Chris")
      |> fill_in(@email_field, with: "c@keathly.io")
      |> click(@save_button)
    end
  end
  ```
  """

  defmacro __using__([]) do
    quote do
      alias Wallaby.Browser
      alias Wallaby.Element
      alias Wallaby.Query
      import Wallaby.Browser
      require Wallaby.Browser
    end
  end
end
