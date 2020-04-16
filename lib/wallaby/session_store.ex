defmodule Wallaby.SessionStore do
  @moduledoc false
  use GenServer

  alias Wallaby.Experimental.Selenium.WebdriverClient

  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def monitor(session) do
    GenServer.call(__MODULE__, {:monitor, session}, 10_000)
  end

  def demonitor(session) do
    GenServer.call(__MODULE__, {:demonitor, session})
  end

  def list_sessions_for(owner_pid \\ self()) when is_pid(owner_pid) do
    :ets.select(:session_store, [{{{:_, :_, :"$1"}, :"$2"}, [{:==, :"$1", owner_pid}], [:"$2"]}])
  end

  def init(:ok) do
    Process.flag(:trap_exit, true)
    :ets.new(:session_store, [:set, :named_table, :public, read_concurrency: true])

    {:ok, nil}
  end

  def handle_call({:monitor, session}, {pid, _ref}, _state) do
    ref = Process.monitor(pid)

    :ets.insert(
      :session_store,
      {{ref, session.id, pid}, session}
    )

    {:reply, :ok, nil}
  end

  def handle_call({:demonitor, session}, _from, _state) do
    result =
      :ets.select(:session_store, [
        {{{:"$1", :"$2", :"$3"}, :"$4"}, [{:==, :"$2", session.id}], [{{:"$1", :"$4"}}]}
      ])

    case result do
      [{ref, _}] ->
        true = Process.demonitor(ref)
        :ets.delete(:session_store, {ref, session.id})

        {:reply, :ok, nil}

      [] ->
        {:reply, :ok, nil}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, _state) do
    [session] =
      :ets.select(:session_store, [{{{:"$1", :"$2", :"$3"}, :"$4"}, [{:==, :"$1", ref}], [:"$4"]}])

    WebdriverClient.delete_session(session)

    :ets.delete(:session_store, {ref, session.id})

    {:noreply, nil}
  end

  def terminate(_reason, _state) do
    :ets.tab2list(:session_store)
    |> Enum.each(fn {_, session} -> close_session(session) end)
  end

  defp close_session(session) do
    WebdriverClient.delete_session(session)
  end
end
