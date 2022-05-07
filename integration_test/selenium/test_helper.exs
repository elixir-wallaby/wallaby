ExUnit.configure(max_cases: 1, timeout: 180_000, exclude: [pending: true])

# Load support files
Code.require_file("../support/test_server.ex", __DIR__)
Code.require_file("../support/pages/index_page.ex", __DIR__)
Code.require_file("../support/pages/page_1.ex", __DIR__)
Code.require_file("../support/session_case.ex", __DIR__)
Code.require_file("../support/helpers.ex", __DIR__)

{:ok, server} = Wallaby.Integration.TestServer.start()
Application.put_env(:wallaby, :base_url, server.base_url)

Application.put_env(
  :wallaby,
  :hackney_options,
  timeout: 30_000,
  recv_timeout: 30_000
)

ExUnit.start()
