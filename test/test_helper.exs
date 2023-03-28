ExUnit.configure(
  exclude: [pending: true],
  max_cases: System.schedulers_online()
)

EventEmitter.start_link([])

ExUnit.start()
