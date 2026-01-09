defmodule Wallaby.SessionStoreTest do
  @moduledoc false
  use ExUnit.Case
  alias Wallaby.SessionStore
  alias Wallaby.Session

  use EventEmitter, :receiver

  setup do
    session_store = start_supervised!({SessionStore, [ets_name: :test_table]})

    [session_store: session_store, table: :sys.get_state(session_store).ets_table]
  end

  describe "monitor/1" do
    test "adds session to the store", %{session_store: session_store, table: table} do
      assert [] == SessionStore.list_sessions_for(name: table)
      session = %Session{id: "foo"}
      :ok = SessionStore.monitor(session_store, session)

      assert [_] = SessionStore.list_sessions_for(name: table)
    end

    test "adds multiple sessions to store", %{session_store: session_store, table: table} do
      assert [] == SessionStore.list_sessions_for(name: table)
      sessions = [%Session{id: "foo"}, %Session{id: "bar"}]

      for session <- sessions do
        :ok = SessionStore.monitor(session_store, session)
      end

      store = SessionStore.list_sessions_for(name: table)

      for session <- sessions do
        assert Enum.member?(store, session)
      end
    end
  end

  describe "demonitor/1" do
    test "removes session from list of active sessions", %{
      session_store: session_store,
      table: table
    } do
      session = %Session{id: "foo"}
      :ok = SessionStore.monitor(session_store, session)
      :ok = SessionStore.demonitor(session_store, session)

      assert [] == SessionStore.list_sessions_for(name: table)
    end

    test "removes a single session from the store", %{
      session_store: session_store,
      table: table
    } do
      assert [] == SessionStore.list_sessions_for(name: table)
      first = %Session{id: "foo"}
      second = %Session{id: "bar"}
      third = %Session{id: "baz"}
      sessions = [first, second, third]

      for session <- sessions do
        :ok = SessionStore.monitor(session_store, session)
      end

      :ok = SessionStore.demonitor(session_store, second)

      store = SessionStore.list_sessions_for(name: table)

      assert Enum.member?(store, first)
      refute Enum.member?(store, second)
      assert Enum.member?(store, third)
    end

    test "flushes DOWN message when demonitoring", %{session_store: session_store, table: table} do
      session = %Session{id: "session_to_flush"}

      test_pid = self()

      owner_pid =
        spawn(fn ->
          :ok = SessionStore.monitor(session_store, session)
          send(test_pid, :monitored)
          receive do: (_ -> :ok)
        end)

      receive do
        :monitored -> :ok
      after
        1000 -> flunk("Failed to monitor session")
      end

      # Suspend SessionStore so we can queue messages
      :sys.suspend(session_store)

      # We spawn a task because GenServer.call will block until SessionStore resumes
      Task.async(fn ->
        SessionStore.demonitor(session_store, session)
      end)

      Process.sleep(50)
      Process.exit(owner_pid, :kill)
      Process.sleep(50)
      :sys.resume(session_store)

      # Ensure all messages are processed (including potentially fatal DOWN)
      :sys.get_state(session_store)

      # Check if SessionStore is still working
      assert [] == SessionStore.list_sessions_for(name: table)
    end
  end

  test "removes sessions when the monitored process dies", %{
    session_store: session_store,
    table: table
  } do
    EventEmitter.add_handler(self())

    # spawn some processes that monitor some sessions
    pids =
      for i <- 1..5 do
        spawn(fn ->
          for j <- 1..i do
            session = %Session{id: "session#{i}#{j}"}
            :ok = SessionStore.monitor(session_store, session)
          end

          receive do
            :done -> :ok
          end
        end)
      end

    # wait for each process to successfully monitor the sessions
    for i <- 1..5,
        j <- 1..i,
        do:
          await(
            :monitor,
            %{monitored_session: %Session{id: "session#{i}#{j}"}},
            Wallaby.SessionStore
          )

    # assert the correct number of sessions are being monitored
    sessions =
      for(pid <- pids, into: [], do: SessionStore.list_sessions_for(name: table, owner_pid: pid))
      |> List.flatten()

    assert 15 == Enum.count(sessions)

    # end each process, causing them to send the DOWN message to store
    for pid <- pids, do: send(pid, :done)

    # wait for each DOWN message to be processed
    for i <- 1..5,
        j <- 1..i,
        do:
          await(
            :DOWN,
            %{monitored_session: %Session{id: "session#{i}#{j}"}},
            Wallaby.SessionStore
          )

    # assert there are no longer any sessions being monitored
    assert for(
             pid <- pids,
             into: [],
             do: SessionStore.list_sessions_for(name: table, owner_pid: pid)
           )
           |> List.flatten()
           |> Enum.empty?()
  end
end
