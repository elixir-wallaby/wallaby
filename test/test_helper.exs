ExUnit.configure(exclude: [pending: true])
ExUnit.start()

Application.ensure_all_started(:bypass)
