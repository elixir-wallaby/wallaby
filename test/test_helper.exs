ExUnit.configure(
  exclude: [pending: true],
  max_cases: min(System.schedulers_online(), 10)
)

EventEmitter.start_link([])

ExUnit.start()
