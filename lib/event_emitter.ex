defmodule EventEmitter do
  @moduledoc """
  This module offers telemetry style event emission for testing purposes.

  If you'd like to emit a message to the event stream, you can call `emit/1` from your implementation code. This is macro, and will not result in any AST injection when not being compiled in the test env.

  ```elixir
  defmodule ImplMod do
    use EventEmitter, :emitter

    def implementation do
      # some logic

      emit %{name: :implementation, module: __MODULE__, metadata: %{unique_identifier: some_variable}}
    end
  end
  ```

  If you'd like to await on a message emitted by implementation code, you can call `await/3` from your test code after registering a handler for your test process

  ```elixir
  defmodule TestMod do
    use EventEmitter, :receiver

    test "some test" do
      EventEmitter.add_handler(self())

      # some tricky asynchronous code

      await :implementation, __MODULE__, %{unique_identifier: some_variable}
    end
  end
  ```

  You can use EventEmitter by starting it in your test helper.

  ```elixir
  # test_helper.exs

  EventEmitter.start_link([])

  ExUnit.start()
  ```
  """

  use GenServer

  @type event :: %{
          optional(:metadata) => map(),
          required(:name) => String.t()
        }

  def emitter do
    quote do
      import EventEmitter, only: [emit: 1]
    end
  end

  def receiver do
    quote do
      import EventEmitter, only: [await: 3]
    end
  end

  defmacro __using__(which) do
    apply(__MODULE__, which, [])
  end

  defmacro emit(event) do
    if Mix.env() == :test do
      quote do
        EventEmitter.emit_event(unquote(event))
      end
    else
      nil
    end
  end

  def await(name, metadata, module) do
    e = {:event, %{metadata: metadata, name: name, module: module}}

    receive do
      ^e -> :ok
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def add_handler(pid), do: GenServer.call(__MODULE__, {:add_handler, pid})
  def emit_event(event), do: GenServer.cast(__MODULE__, {:event, event})

  @impl GenServer
  def init(_) do
    {:ok, %{handlers: []}}
  end

  @impl GenServer
  def handle_call({:add_handler, pid}, _, state) do
    {:reply, pid, %{state | handlers: [pid | state.handlers]}}
  end

  @impl GenServer
  def handle_cast({:event, event}, %{handlers: handlers} = state) do
    for h <- handlers do
      send(h, {:event, event})
    end

    {:noreply, state}
  end
end
