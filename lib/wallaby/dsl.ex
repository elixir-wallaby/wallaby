defmodule Wallaby.DSL do
  @moduledoc """
  Sets up the Wallaby DSL in a module.

  All functions in `Wallaby.Browser` are now accessible without a module name
  and `Wallaby.Browser`, `Wallaby.Element` and `Wallaby.Query` are all aliased.

  ## Example

  ```elixir
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

      # Kernel.tap/2 was introduced in 1.12 and conflicts with Browser.tap/2
      import Kernel, except: [tap: 2]
      import Wallaby.Browser
    end
  end
end
