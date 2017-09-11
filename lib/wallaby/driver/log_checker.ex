defmodule Wallaby.Driver.LogChecker do
  @moduledoc false
  alias Wallaby.Driver.LogStore

  def check_logs!(%{driver: driver} = session, fun) do
    return_value = fun.()

    {:ok, logs} = driver.log(session)

    session.session_url
    |> LogStore.append_logs(logs)
    |> Enum.each(&driver.parse_log/1)

    return_value
  end
end
