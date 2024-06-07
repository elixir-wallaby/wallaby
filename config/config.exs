import Config

config :wallaby,
  max_wait_time: 5000,
  pool_size: 3,
  js_logger: :stdio,
  screenshot_on_failure: false,
  js_errors: true,
  hackney_options: [timeout: :infinity, recv_timeout: :infinity]

import_config "#{config_env()}.exs"
