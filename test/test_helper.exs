ExUnit.configure(exclude: [pending: true])
EventEmitter.start_link([])

IO.inspect(System.schedulers_online(), label: "online schedulers")

ExUnit.start()
