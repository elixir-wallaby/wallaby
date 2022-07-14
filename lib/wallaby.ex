defmodule Wallaby do
  @moduledoc """
  A concurrent feature testing library.

  ## Configuration

  Wallaby supports the following options:

  * `:otp_app` - The name of your OTP application. This is used to check out your Ecto repos into the SQL Sandbox.
  * `:screenshot_dir` - The directory to store screenshots.
  * `:screenshot_on_failure` - if Wallaby should take screenshots on test failures (defaults to `false`).
  * `:max_wait_time` - The amount of time that Wallaby should wait to find an element on the page. (defaults to `3_000`)
  * `:js_errors` - if Wallaby should re-throw JavaScript errors in elixir (defaults to true).
  * `:js_logger` - IO device where JavaScript console logs are written to. Defaults to :stdio. This option can also be set to a file or any other io device. You can disable JavaScript console logging by setting this to `nil`.
  """

  @drivers %{
    "chrome" => Wallaby.Chrome,
    "selenium" => Wallaby.Selenium
  }

  use Application

  alias Wallaby.Session
  alias Wallaby.SessionStore

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    case driver().validate() do
      :ok -> :ok
      {:error, exception} -> raise exception
    end

    children = [
      {driver(), [name: Wallaby.Driver.Supervisor]},
      :hackney_pool.child_spec(:wallaby_pool,
        timeout: 15_000,
        max_connections: System.schedulers_online()
      ),
      {Wallaby.SessionStore, [name: Wallaby.SessionStore]}
    ]

    opts = [strategy: :one_for_one, name: Wallaby.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @type reason :: any
  @type start_session_opts :: {atom, any}

  @doc """
  Starts a browser session.

  ## Multiple sessions

  Each session runs in its own browser so that each test runs in isolation.
  Because of this isolation multiple sessions can be created for a test:

  ```
  @message_field Query.text_field("Share Message")
  @share_button Query.button("Share")
  @message_list Query.css(".messages")

  test "That multiple sessions work" do
    {:ok, user1} = Wallaby.start_session
    user1
    |> visit("/page.html")
    |> fill_in(@message_field, with: "Hello there!")
    |> click(@share_button)

    {:ok, user2} = Wallaby.start_session
    user2
    |> visit("/page.html")
    |> fill_in(@message_field, with: "Hello yourself")
    |> click(@share_button)

    assert user1 |> find(@message_list) |> List.last |> text == "Hello yourself"
    assert user2 |> find(@message_list) |> List.first |> text == "Hello there"
  end
  ```
  """
  @spec start_session([start_session_opts]) :: {:ok, Session.t()} | {:error, reason}
  def start_session(opts \\ []) do
    with {:ok, session} <- driver().start_session(opts),
         :ok <- SessionStore.monitor(session),
         do: {:ok, session}
  end

  @doc """
  Ends a browser session.
  """
  @spec end_session(Session.t()) :: :ok | {:error, reason}
  def end_session(%Session{driver: driver} = session) do
    with :ok <- SessionStore.demonitor(session) do
      driver.end_session(session)
    end
  end

  @doc false
  def screenshot_on_failure? do
    Application.get_env(:wallaby, :screenshot_on_failure)
  end

  @doc false
  def js_errors? do
    Application.get_env(:wallaby, :js_errors, true)
  end

  @doc false
  def js_logger do
    Application.get_env(:wallaby, :js_logger, :stdio)
  end

  def driver do
    Map.get(
      @drivers,
      System.get_env("WALLABY_DRIVER"),
      Application.get_env(:wallaby, :driver, Wallaby.Chrome)
    )
  end
end
