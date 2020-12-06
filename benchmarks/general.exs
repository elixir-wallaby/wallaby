{:ok, server} = Wallaby.Integration.TestServer.start
Application.put_env(:wallaby, :base_url, server.base_url)

use Wallaby.DSL

{:ok, session} = Wallaby.start_session

session = visit(session, "forms.html")

text_field_query = Query.text_field("name")
id_css_query = Query.css("#button-no-type-id")

Benchee.run(%{
  "fill_in text_field" => fn ->
    fill_in(session, text_field_query, with: "Chris")
  end,
  "visit forms" => fn ->
    visit(session, "forms.html")
  end,
  "find by css #id" => fn ->
    find(session, id_css_query)
  end
},
time: 18)

Wallaby.end_session(session)

# tobi@comfy ~/github/wallaby $ mix run benchmarks/general.exs
# Erlang/OTP 19 [erts-8.1] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.4.2
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 18.0s
# parallel: 1
# inputs: none specified
# Estimated total run time: 60.0s
#
# Benchmarking fill_in text_field...
# Benchmarking find by css #id...
# Benchmarking visit forms...
# Generated benchmarks/html/general.html
#
# Name                         ips        average  deviation         median
# visit forms                 7.19      139.09 ms    ±29.23%      124.11 ms
# find by css #id             4.90      204.10 ms     ±6.42%      206.89 ms
# fill_in text_field          2.23      448.84 ms     ±5.41%      448.80 ms
#
# Comparison:
# visit forms                 7.19
# find by css #id             4.90 - 1.47x slower
# fill_in text_field          2.23 - 3.23x slower
