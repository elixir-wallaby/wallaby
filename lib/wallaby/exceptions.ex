defmodule Wallaby.AmbiguousMatch do
  defexception [:message]
end

defmodule Wallaby.ElementNotFound do
  defexception [:message]
end

defmodule Wallaby.ExpectationNotMet do
  defexception [:message]
end
