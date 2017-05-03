defmodule Wallaby.Integration.WallabyTest do
  use Wallaby.Integration.SessionCase, async: true

  describe "end_session/2" do
    test "calling end_session on an active session", %{session: session} do
      assert :ok = Wallaby.end_session(session)
    end

    test "calling end_session on an already closed session", %{session: session} do
      Wallaby.end_session(session)

      assert :ok = Wallaby.end_session(session)
    end
  end
end
