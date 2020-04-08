ExUnit.configure(exclude: [pending: true], formatters: [Wallaby.Feature.Formatter])
ExUnit.start()

Application.ensure_all_started(:bypass)
