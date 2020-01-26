defmodule Wallaby.TestSupport.JSONWireProtocolResponses do
  @moduledoc """
  Server response generator for the JSONWireProtocol.
  """

  def start_session_response(opts \\ []) do
    session_id = Keyword.get(opts, :session_id, "sample_session")

    %{"sessionId" => session_id, "value" => %{}, "status" => 0}
  end
end
