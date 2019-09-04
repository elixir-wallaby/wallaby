defmodule Wallaby.SessionStore do
  @moduledoc false
  use GenServer

  alias Wallaby.Experimental.Selenium.WebdriverClient

  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def monitor(session), do: GenServer.call(__MODULE__, {:monitor, session}, 10_000)

  def demonitor(session), do: GenServer.call(__MODULE__, {:demonitor, session})

  def init(:ok) do
    Process.flag(:trap_exit, true)
    {:ok, %{refs: %{}}}
  end

  def handle_call({:monitor, session}, {pid, _ref}, %{refs: refs} = state) do
    ref = Process.monitor(pid)
    refs = Map.put(refs, ref, session)
    {:reply, :ok, %{state | refs: refs}}
  end

  def handle_call({:demonitor, session}, _from, %{refs: refs} = state) do
    case Enum.find(refs, fn({_, value}) -> value.id == session.id end) do
      {ref, _} ->
        {_, refs} = Map.pop(refs, ref)
        true = Process.demonitor(ref)
        {:reply, :ok, %{state | refs: refs}}
      nil ->
        {:reply, :ok, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{refs: refs} = state) do
    {session, refs} = Map.pop(refs, ref)
    WebdriverClient.delete_session(session)
    {:noreply, %{state | refs: refs}}
  end

  def terminate(_reason, %{refs: refs}) do
    Enum.each(refs, fn({_ref, session}) -> close_session(session) end)
  end

  defp close_session(session) do
    WebdriverClient.delete_session(session)
  end
end
