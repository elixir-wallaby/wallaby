defmodule Wallaby.Driver.LogStore do
  @moduledoc false

  use Agent

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)

    Agent.start_link(fn -> Map.new() end, opts)
  end

  @doc """
  Appends logs to a session
  """
  def append_logs(session, logs, log_store \\ __MODULE__)

  def append_logs(session, logs, log_store) when is_binary(session) and not is_list(logs) do
    append_logs(session, List.wrap(logs), log_store)
  end

  def append_logs(session, logs, log_store) when is_binary(session) do
    Agent.get_and_update(log_store, fn map ->
      Map.get_and_update(map, session, fn
        nil -> unique_logs([], logs)
        old_logs -> unique_logs(old_logs, logs)
      end)
    end)
  end

  def get_logs(session, log_store \\ __MODULE__) when is_binary(session) do
    Agent.get(log_store, fn map -> Map.get(map, session) end)
  end

  defp unique_logs(old_logs, new_logs) do
    union = new_logs -- old_logs
    {union, old_logs ++ union}
  end
end
