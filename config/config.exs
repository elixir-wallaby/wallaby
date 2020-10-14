use Mix.Config

config :wallaby,
  driver: Wallaby.Selenium,
  max_wait_time: 5000,
  pool_size: 3,
  js_logger: :stdio,
  screenshot_on_failure: false,
  js_errors: true,
  hackney_options: [timeout: :infinity, recv_timeout: :infinity]

import_config "#{Mix.env()}.exs"
