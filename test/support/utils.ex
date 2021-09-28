defmodule Wallaby.TestSupport.Utils do
  @moduledoc """
  This module contains generic testing helpers.
  """

  @doc """
  Repeatedly execute a closure, with a timeout. Useful for assertions that are relying on asynchronous operations.
  """
  def attempt_with_timeout(doer, timeout \\ 100),
    do: attempt_with_timeout(doer, now_in_milliseconds(), timeout)

  defp attempt_with_timeout(doer, start, timeout) do
    doer.()
  rescue
    e ->
      passed_timeout? = now_in_milliseconds() - start >= timeout

      if passed_timeout? do
        reraise e, __STACKTRACE__
      else
        attempt_with_timeout(doer, start, timeout)
      end
  end

  defp now_in_milliseconds(), do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)
end
