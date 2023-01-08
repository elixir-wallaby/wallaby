defmodule Wallaby.Chrome.DefaultPartitionCount do
  @moduledoc """
  Wallaby uses this module to choose a reasonable number of partitions. It considers the number of
  CPU cores in doing so.

  When the user configures a specific number of partitions, then this module does not come into
  play at all. Wallaby obeys the config.

  ## Motivation
  We want Wallaby to **just work** where we can make it so.

  ### The Nature of Incremental Performance
  As CPU Cores increase, we see at first Increasing Returns in the form of tests running faster.
  Going from 1 core to 2 cores is a big improvement, for example.

  There is a a threshold number of cores at which we enter the realm of Diminishing Returns.

  Going from 2 cores to 3 cores still helps, but less so than from 1 to 2. And from 8 to 9 may
  still provide benefit, but again to a lesser degree.

  And then at some higher threshold number of cores, we see Decreasing Returns.

  This may be counterintuitive. It is certainly problem-dependent. But most workloads are not
  perfectly partitionable.

  Run the Wallaby test suite on a 56-core machine while spinning up 56 partitions. Then run it
  again on the same machine but spinning up only 9 partitions.

  Which one runs faster? 9 partitions. And it's not even close. The run with 56 partitions took
  ~4x the time as the run using only 9 partitions. More importantly, the 56-partition tests gave
  false negatives due to various timeout issues.

  ### Threshold Values
  We don't yet know precisely where the thresholds lie. But we do know that 56 partitions on a
  56-core machine is beyond the Decreasing Returns threshold.

  By experiment, 9 partitions performed the best on the 56-core machine.

  Using this heuristic, Wallaby will use only one-sixth of the cores on machines having 56 or
  more.

  Unless you configure a specific number of :partitions, of course. Wallaby will always use that
  if you specify it.

  It's very likely that the point of Decreasing Returns happens at a LOWER core threshold.

  We made this module easy to enhance as users discover lower thresholds. Or better default
  choices for the number of partitions.

  ### Symptoms
  What happens when you spin up 56 partitions on a 56-core machine? Report is
  [here](https://github.com/elixir-wallaby/wallaby/issues/720).

  """
  @decreasing_returns_threshold 56
  @core_divisor_at_or_above_threshold 6

  @spec choose((() -> pos_integer)) :: pos_integer()
  def choose(nil = _fn_count_cpu_cores) do
    choose(&System.schedulers_online/0)
  end

  def choose(fn_count_cpu_cores)
      when is_function(fn_count_cpu_cores, 0) do
    choose_wisely(fn_count_cpu_cores.())
  end

  # ┌--------------------------------------------------------------------------------------------┐
  # │                       call-depth 1 functions, in order of reference                        │
  # └--------------------------------------------------------------------------------------------┘
  defp choose_wisely(cpu_cores) when is_integer(cpu_cores) and cpu_cores > 0 do
    reasonable_number_of_partitions(cpu_cores)
  end

  # ┌--------------------------------------------------------------------------------------------┐
  # │                       call-depth 2 functions, in order of reference                        │
  # └--------------------------------------------------------------------------------------------┘
  defp reasonable_number_of_partitions(cpu_cores)
       when cpu_cores >= @decreasing_returns_threshold do
    Integer.floor_div(cpu_cores, @core_divisor_at_or_above_threshold)
  end

  defp reasonable_number_of_partitions(cpu_cores) do
    cpu_cores
  end
end
