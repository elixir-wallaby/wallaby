defmodule Wallaby.Chrome.Logger do
  @moduledoc false
  @log_regex ~r/^(?<url>\S+) (?<line>\d+):(?<column>\d+) (?<message>.*)$/s
  @string_regex ~r/^"(?<string>.+)"$/

  def parse_log(%{"level" => "SEVERE", "source" => "javascript", "message" => msg}) do
    if Wallaby.js_errors?() do
      raise Wallaby.JSError, msg
    end
  end

  def parse_log(%{"level" => "INFO", "source" => "console-api", "message" => msg}) do
    if Wallaby.js_logger() do
      case Regex.named_captures(@log_regex, msg) do
        %{"message" => message} -> print_message(message)
      end
    end
  end

  def parse_log(_), do: nil

  defp print_message(message) do
    message =
      case Regex.named_captures(@string_regex, message) do
        %{"string" => string} -> format_string(string)
        nil -> message
      end

    IO.puts(Wallaby.js_logger(), message)
  end

  defp format_string(message) do
    unescaped = String.replace(message, ~r/\\(.)/, "\\1")

    case Jason.decode(unescaped) do
      {:ok, data} -> "\n#{Jason.encode!(data, pretty: true)}"
      {:error, _} -> unescaped
    end
  end
end
