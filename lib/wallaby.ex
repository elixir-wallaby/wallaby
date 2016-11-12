defmodule Wallaby do
  @moduledoc """
  A concurrent feature testing library.

  ## Configuration

  Wallaby supports the following options:

  * `:pool_size` - Maximum amount of phantoms to run. The default is `:erlang.system_info(:schedulers_online) * 2`.
  * `:screenshot_dir` - The directory to store screenshots.
  * `:screenshot_on_failure` - if Wallaby should take screenshots on test failures (defaults to `false`).
  * `:max_wait_time` - The amount of time that Wallaby should wait to find an element on the page. (defaults to `3_000`)
  * `:js_errors` - if Wallaby should re-throw javascript errors in elixir (defaults to true).
  * `:js_logger` - IO device where javascript console logs are written to. Defaults to :stdio. This option can also be set to a file or any other io device. You can disable javascript console logging by setting this to `nil`.
  * `:phantomjs` - The path to the phantomjs executable (defaults to "phantomjs")
  * `:phantomjs_args` - Any extra arguments that should be passed to phantomjs (defaults to "")
  """
  use Application


  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(driver, [[name: Driver.Supervisor]])
    ]

    opts = [strategy: :one_for_one, name: Wallaby.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_session(opts \\ []) do
    driver.start_session(opts)
  end

  def end_session(session) do
    driver.end_session(session)
  end

  def screenshot_on_failure? do
    Application.get_env(:wallaby, :screenshot_on_failure)
  end

  def js_errors? do
    Application.get_env(:wallaby, :js_errors, true)
  end

  def js_logger do
    Application.get_env(:wallaby, :js_logger, :stdio)
  end

  def phantomjs_path do
    Application.get_env(:wallaby, :phantomjs, "phantomjs")
  end

  def driver do
    Application.get_env(:wallaby, :driver, Wallaby.Phantom)
  end
end
