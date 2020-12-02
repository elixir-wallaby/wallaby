defmodule Wallaby.SessionStoreTest do
  @moduledoc false
  use ExUnit.Case
  alias Wallaby.SessionStore

  describe "monitor/1" do
    test "adds session to list of active sessions" do
      assert [] = SessionStore.list_sessions_for()
      {:ok, session} = Wallaby.driver().start_session([])
      :ok = SessionStore.monitor(session)
      assert [_session] = SessionStore.list_sessions_for()
    end
  end

  describe "demonitor/1" do
    test "removes session from list of active sessions" do
      {:ok, session} = Wallaby.driver().start_session([])
      :ok = SessionStore.monitor(session)
      :ok = SessionStore.demonitor(session)
      assert [] = SessionStore.list_sessions_for()
    end
  end
end
