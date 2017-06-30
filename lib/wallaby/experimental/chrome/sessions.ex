defmodule Wallaby.Experimental.Chrome.Sessions do
  use GenServer

  alias Wallaby.Experimental.Selenium.WebdriverClient


  def start_link(), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def monitor(session), do: GenServer.call(__MODULE__, {:monitor, session})

  def init(:ok) do
    Process.flag(:trap_exit, true)
    {:ok, %{refs: %{}}}
  end

  def handle_call({:monitor, session}, {pid, _ref}, %{refs: refs}=state) do
    ref = Process.monitor(pid)
    refs = Map.put(refs, ref, session)
    {:reply, :ok, %{state | refs: refs}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{refs: refs}=state) do
    IO.puts("Killing session")
    {session, _ref} = Map.pop(refs, ref)
    WebdriverClient.delete_session(session)
    {:noreply, %{state | refs: refs}}
  end

  def terminate(_reason, %{refs: _refs}) do
    IO.puts("Terminating")
    # Enum.each(refs, fn({_ref, session}) -> close_session(session) end)
  end

  # defp close_session(session) do
  #   WebdriverClient.delete_session(session)
  # end
end
