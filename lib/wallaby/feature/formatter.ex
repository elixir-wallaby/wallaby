defmodule Wallaby.Feature.Formatter do
  use GenServer

  @impl GenServer
  def init(config) do
    {:ok, config}
  end

  @impl GenServer
  def handle_cast({:module_finished, %ExUnit.TestModule{state: {:failed, failures}} = test_module}, config) do
    IO.puts "Screenshot taken..."
    {:noreply, config}
  end

  @impl GenServer
  def handle_cast(_, config) do
    {:noreply, config}
  end
end
