defmodule Wallaby.Phantom.Logger do
  @line_number_regex ~r/\s\((undefined)?:(undefined)?\)$/

  def log(logs) when is_list(logs) do
    logs
    |> Enum.each(&parse_log/1)
  end

  def parse_log(%{"level" => "WARNING", "message" => msg}) do
    if Wallaby.js_errors? do
      raise Wallaby.JSError, msg
    end
  end

  def parse_log(%{"level" => "INFO", "message" => msg}) do
    @line_number_regex
    |> Regex.replace(msg, "")
    |> IO.puts()
  end

  def parse_log(_), do: nil
end
