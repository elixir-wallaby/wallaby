defmodule Wallaby.Phantom.Webdriver.Client do
  @moduledoc false

  alias Wallaby.Session
  alias Wallaby.Webdriver.Client

  @doc """
  Executes javascript using phantomjs specific endpoint
  """
  @spec execute_script(Session.t, String.t, list(any)) :: {:ok, any}
  def execute_script(session, script, arguments) do
    with {:ok, resp} <- Client.request(:post, "#{session.session_url}/phantom/execute", %{script: script, args: arguments}),
          {:ok, value} <- Map.fetch(resp, "value"),
      do: {:ok, value}
  end
end
