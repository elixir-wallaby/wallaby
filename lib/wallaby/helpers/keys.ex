defmodule Wallaby.Helpers.KeyCodes do

  def json(keys) do
    unicode_string = Enum.map(keys, fn(key)-> "\"#{code(key)}\"" end)
    |> Enum.join(",")
    "{\"value\": [#{unicode_string}]}"
  end

  defp code(:enter), do: "\\uE007"
  defp code(:tab), do: "\\uE004"

end
