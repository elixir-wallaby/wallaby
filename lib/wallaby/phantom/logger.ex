defmodule Wallaby.Phantom.Logger do
  @moduledoc false
  @line_number_regex ~r/\s\((undefined)?:(undefined)?\)$/

  def parse_log(%{"level" => "WARNING", "message" => msg}) do
    if Wallaby.js_errors?() do
      raise Wallaby.JSError, msg
    end
  end

  def parse_log(%{"level" => "INFO", "message" => msg}) do
    if Wallaby.js_logger() do
      msg = Regex.replace(@line_number_regex, msg, "")
      IO.puts(Wallaby.js_logger(), msg)
    end
  end

  def parse_log(_), do: nil
end
