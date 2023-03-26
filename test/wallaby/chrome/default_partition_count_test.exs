defmodule Wallaby.Chrome.DefaultPartitionCountTest do
  use ExUnit.Case, async: true

  # alias Wallaby.Chrome.DefaultPartitionCount

  # describe "choose/1" do
  #   for cpu_cores <- 1..55 do
  #     test "will choose #{cpu_cores} partitions on a #{cpu_cores}-core machine" do
  #       cores = unquote(cpu_cores)
  #       expected = cores

  #       actual = DefaultPartitionCount.choose(fn -> cores end)

  #       assert actual == expected
  #     end
  #   end

  #   for cpu_cores <- 56..59 do
  #     test "will choose 9 partitions on a #{cpu_cores}-core machine" do
  #       cores = unquote(cpu_cores)
  #       expected = 9

  #       actual = DefaultPartitionCount.choose(fn -> cores end)

  #       assert actual == expected
  #     end
  #   end

  #   for cpu_cores <- 60..65 do
  #     test "will choose 10 partitions on a #{cpu_cores}-core machine" do
  #       cores = unquote(cpu_cores)
  #       expected = 10

  #       actual = DefaultPartitionCount.choose(fn -> cores end)

  #       assert actual == expected
  #     end
  #   end

  #   for cpu_cores <- 120..125 do
  #     test "will choose 20 partitions on a #{cpu_cores}-core machine" do
  #       cores = unquote(cpu_cores)
  #       expected = 20

  #       actual = DefaultPartitionCount.choose(fn -> cores end)

  #       assert actual == expected
  #     end
  #   end
  # end
end
