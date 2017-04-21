ExUnit.configure(max_cases: 2, exclude: [pending: true])
ExUnit.start()

# Load support files
Code.require_file "../support/test_server.ex", __DIR__
Code.require_file "../support/session_case.ex", __DIR__

{:ok, server} = Wallaby.Integration.TestServer.start
Application.put_env(:wallaby, :base_url, server.base_url)
