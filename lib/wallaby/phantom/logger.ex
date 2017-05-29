defmodule Wallaby.Phantom.Logger do
  @moduledoc false
  @line_number_regex ~r/\s\((undefined)?:(undefined)?\)$/

  def log(logs) when is_list(logs) do
    logs
    |> Enum.each(&parse_log/1)
  end

  def log(log) do
    cond do
      log =~ "page.onConsoleMessage" ->
        #IO.puts(log)
        handle_console_message(log)
        #parse_log(log)
      log =~ "page.onError" ->
         IO.puts log
         handle_error_message(log)
      true ->
        :ok
    end
  end

  def parse_log(%{"level" => "WARNING", "message" => msg}) do
    if Wallaby.js_errors? do
      raise Wallaby.JSError, msg
    end
  end

  def parse_log(%{"level" => "INFO", "message" => msg}) do
    if Wallaby.js_logger do
      msg = Regex.replace(@line_number_regex, msg, "")
      IO.puts(Wallaby.js_logger, msg)
    end
  end

  def parse_log(_), do: nil

  def handle_console_message(log) do
    if Wallaby.js_logger do
      message = log
      |> String.split([" - "])
      |> List.last

      IO.puts(Wallaby.js_logger, message)
    end
  end

  def handle_error_message(log) do
    if Wallaby.js_errors? do
      message = log
      |> String.split([" - "])
      |> List.last

      raise Wallaby.JSError, message
    end
  end
  def handle_console_message(_), do: nil

end
