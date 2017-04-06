{:ok, server} = Wallaby.TestServer.start
Application.put_env(:wallaby, :base_url, server.base_url)

ExUnit.configure(exclude: [pending: true])
ExUnit.start()

Application.ensure_all_started(:bypass)
