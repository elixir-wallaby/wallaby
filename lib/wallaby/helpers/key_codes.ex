defmodule Wallaby.Helpers.KeyCodes do
  @moduledoc false

  # Helper utility for converting key atoms into key codes suitable to send over
  # the wire.

  @doc """
  Encode a list of key codes to a usable JSON representation.
  """
  @spec json(list(atom)) :: String.t()
  def json(keys) when is_list(keys) do
    unicode =
      keys
      |> Enum.reduce([], fn x, acc -> acc ++ split_strings(x) end)
      |> Enum.map(&"\"#{code(&1)}\"")
      |> Enum.join(",")

    "{\"value\": [#{unicode}]}"
  end

  @doc """
  Ensures a list of keys are in binary
  form to check for local files.
  """
  @spec chars(list() | binary()) :: [binary()]
  def chars(keys) do
    keys
    |> List.wrap()
    |> Enum.map(fn
      a when is_atom(a) -> code(a)
      s -> s
    end)
  end

  defp split_strings(x) when is_binary(x), do: String.graphemes(x)
  defp split_strings(x), do: [x]

  defp code(:null), do: "\\uE000"
  defp code(:cancel), do: "\\uE001"
  defp code(:help), do: "\\uE002"
  defp code(:backspace), do: "\\uE003"
  defp code(:tab), do: "\\uE004"
  defp code(:clear), do: "\\uE005"
  defp code(:return), do: "\\uE006"
  defp code(:enter), do: "\\uE007"
  defp code(:shift), do: "\\uE008"
  defp code(:control), do: "\\uE009"
  defp code(:alt), do: "\\uE00A"
  defp code(:pause), do: "\\uE00B"
  defp code(:escape), do: "\\uE00C"

  defp code(:space), do: "\\uE00D"
  defp code(:pageup), do: "\\uE00E"
  defp code(:pagedown), do: "\\uE00F"
  defp code(:end), do: "\\uE010"
  defp code(:home), do: "\\uE011"
  defp code(:left_arrow), do: "\\uE012"
  defp code(:up_arrow), do: "\\uE013"
  defp code(:right_arrow), do: "\\uE014"
  defp code(:down_arrow), do: "\\uE015"
  defp code(:insert), do: "\\uE016"
  defp code(:delete), do: "\\uE017"
  defp code(:semicolon), do: "\\uE018"
  defp code(:equals), do: "\\uE019"

  defp code(:num0), do: "\\uE01A"
  defp code(:num1), do: "\\uE01B"
  defp code(:num2), do: "\\uE01C"
  defp code(:num3), do: "\\uE01D"
  defp code(:num4), do: "\\uE01E"
  defp code(:num5), do: "\\uE01F"
  defp code(:num6), do: "\\uE020"
  defp code(:num7), do: "\\uE021"
  defp code(:num8), do: "\\uE022"
  defp code(:num9), do: "\\uE023"

  defp code(:multiply), do: "\\uE024"
  defp code(:add), do: "\\uE025"
  defp code(:seperator), do: "\\uE026"
  defp code(:subtract), do: "\\uE027"
  defp code(:decimal), do: "\\uE028"
  defp code(:divide), do: "\\uE029"

  defp code(:command), do: "\\uE03D"

  defp code(char), do: char
end
