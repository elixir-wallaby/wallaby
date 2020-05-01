defmodule Wallaby.Utils.ResourcePoolTest do
  use ExUnit.Case

  alias Wallaby.Utils.ResourcePool

  defmodule TestProcess do
    use Agent

    @default_value "hello"

    def start_link(arg) do
      initial_value =
        case arg do
          [] -> @default_value
          value -> value
        end

      Agent.start_link(fn -> initial_value end)
    end

    def default_value, do: @default_value
    def get_value(pid), do: Agent.get(pid, & &1)
  end

  test "works when started with child_spec", context do
    assert {:ok, pool_pid} =
             start_supervised({ResourcePool, name: context.test, worker: TestProcess})

    assert {:ok, process_pid} = ResourcePool.checkout(pool_pid)

    assert TestProcess.get_value(process_pid) == TestProcess.default_value()
  end

  test "allows passing options to the worker process", context do
    assert {:ok, pool_pid} =
             start_supervised({ResourcePool, name: context.test, worker: {TestProcess, "foo"}})

    assert {:ok, process_pid} = ResourcePool.checkout(pool_pid)

    assert TestProcess.get_value(process_pid) == "foo"
  end

  test "does not start when missing :name" do
    assert_raise KeyError, fn ->
      start_supervised({ResourcePool, worker: TestProcess})
    end
  end

  test "does not start when missing :worker", context do
    assert_raise KeyError, fn ->
      start_supervised({ResourcePool, name: context.test})
    end
  end

  test "size option limits the size", context do
    assert {:ok, pool_pid} =
             start_supervised(
               {ResourcePool, name: context.test, worker: TestProcess, size: 1, max_overflow: 0}
             )

    assert {:ok, process_pid} = ResourcePool.checkout(pool_pid, block?: false)
    assert {:error, :full} = ResourcePool.checkout(pool_pid, block?: false)

    assert :ok = ResourcePool.checkin(pool_pid, process_pid)

    assert {:ok, ^process_pid} = ResourcePool.checkout(pool_pid, block?: false)
  end
end
