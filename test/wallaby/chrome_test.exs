defmodule Wallaby.ChromeTest do
  use ExUnit.Case, async: true
  alias Wallaby.Chrome

  import Wallaby.SettingsTestHelpers

  setup do
    ensure_setting_is_reset(:wallaby, :chromedriver)
  end

  describe "init/1" do
    for partitions <- 1..128 do
      test "when configured for #{partitions} partitions, init returns with #{partitions} partitions" do
        partition_count = unquote(partitions)

        Application.put_env(:wallaby, :chromedriver, partitions: partition_count)

        actual =
          :meaningless_init_arg
          |> Chrome.init()
          |> extract_partition_count()

        assert actual == partition_count
      end
    end

    for cpu_cores <- 1..55 do
      test "when partitions have not been explicitly configured, will choose #{cpu_cores} partitions on a #{cpu_cores}-core machine" do
        cores = unquote(cpu_cores)
        expected = cores
        Application.put_env(:wallaby, :chromedriver, system_cores_fn: fn -> cores end)

        actual =
          :meaningless_init_arg
          |> Chrome.init()
          |> extract_partition_count()

        assert actual == expected
      end
    end

    for cpu_cores <- 56..59 do
      test "when partitions have not been explicitly configured, will choose 9 partitions on a #{cpu_cores}-core machine" do
        cores = unquote(cpu_cores)
        expected = 9
        Application.put_env(:wallaby, :chromedriver, system_cores_fn: fn -> cores end)

        actual =
          :meaningless_init_arg
          |> Chrome.init()
          |> extract_partition_count()

        assert actual == expected
      end
    end

    for cpu_cores <- 60..65 do
      test "when partitions have not been explicitly configured, will choose 10 partitions on a #{cpu_cores}-core machine" do
        cores = unquote(cpu_cores)
        expected = 10
        Application.put_env(:wallaby, :chromedriver, system_cores_fn: fn -> cores end)

        actual =
          :meaningless_init_arg
          |> Chrome.init()
          |> extract_partition_count()

        assert actual == expected
      end
    end

    for cpu_cores <- 120..125 do
      test "when partitions have not been explicitly configured, will choose 20 partitions on a #{cpu_cores}-core machine" do
        cores = unquote(cpu_cores)
        expected = 20
        Application.put_env(:wallaby, :chromedriver, system_cores_fn: fn -> cores end)

        actual =
          :meaningless_init_arg
          |> Chrome.init()
          |> extract_partition_count()

        assert actual == expected
      end
    end
  end

  # ┌--------------------------------------------------------------------------------------------┐
  # │                       call-depth 1 functions, in order of reference                        │
  # └--------------------------------------------------------------------------------------------┘
  defp extract_partition_count({:ok, {_, children}}) when is_list(children) do
    children
    |> extract_chromedrivers_child()
    |> extract_start_tuple()
    |> extract_start_args()
    |> extract_keyword_list()
    |> extract_partitions_value()
  end

  # ┌--------------------------------------------------------------------------------------------┐
  # │                       call-depth 2 functions, in order of reference                        │
  # └--------------------------------------------------------------------------------------------┘
  defp extract_chromedrivers_child(children) when is_list(children) do
    children
    |> Enum.find(fn _candidate = %{:id => candidate_id} ->
      Wallaby.Chromedrivers == candidate_id
    end)
  end

  defp extract_start_tuple(_a_child_spec = %{:start => start}) when is_tuple(start) do
    start
  end

  defp extract_start_args(_start_tuple = {_module, _function, args}) when is_list(args) do
    args
  end

  defp extract_keyword_list(_from_start_args = [keyword_list]) when is_list(keyword_list) do
    keyword_list
  end

  defp extract_partitions_value(from_keyword_list) when is_list(from_keyword_list) do
    Keyword.get(from_keyword_list, :partitions)
  end
end
