defmodule Wallaby.Phantom.LogStore do
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  @doc """
  Appends logs to a session
  """
  def append_logs(session, logs) when is_binary(session) do
    Agent.get_and_update __MODULE__, fn(map) ->
      Map.get_and_update map, session, fn
        nil      -> unique_logs([], logs)
        old_logs -> unique_logs(old_logs, logs)
      end
    end
  end

  def get_logs(session) when is_binary(session) do
    Agent.get(__MODULE__, fn map -> Map.get(map, session) end)
  end

  defp unique_logs(old_logs, new_logs) do
    union = (new_logs -- old_logs)
    {union, old_logs ++ union}
  end
end
