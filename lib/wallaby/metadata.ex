defmodule Wallaby.Metadata do
  @moduledoc false

  # Metadata is used to encode information about the browser and test. This
  # information is then stored in a User Agent string. The information from the
  # test can then be extracted in the application.

  @prefix "BeamMetadata"
  @regex ~r{#{@prefix} \((.*?)\)}

  def append(user_agent, nil), do: user_agent

  def append(user_agent, metadata) when is_map(metadata) or is_list(metadata) do
    append(user_agent, format(metadata))
  end

  def append(user_agent, metadata) when is_binary(metadata) do
    "#{user_agent}/#{metadata}"
  end

  @doc """
  Formats a string to a valid UserAgent string.
  """
  def format(metadata) do
    encoded =
      {:v1, metadata}
      |> :erlang.term_to_binary()
      |> Base.url_encode64()

    "#{@prefix} (#{encoded})"
  end

  def extract(str) do
    ua =
      str
      |> String.split("/")
      |> List.last()

    case Regex.run(@regex, ua) do
      [_, metadata] -> parse(metadata)
      _ -> %{}
    end
  end

  def parse(encoded_metadata) do
    encoded_metadata
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()
    |> case do
      {:v1, metadata} -> metadata
      _ -> raise Wallaby.BadMetadataError, message: "#{encoded_metadata} is not valid"
    end
  end
end
