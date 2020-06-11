defmodule Wallaby.Feature do
  @moduledoc """
  Helpers for writing features.

  You can `use` or `import` this module.

  ## use Wallaby.Feature

  Calling this module with `use` will automatically call `use Wallaby.DSL`.

  When called with `use` and you are using Ecto, please configure your `otp_app`.

  ```
  config :wallaby, otp_app: :your_app
  ```
  """

  @includes_ecto Code.ensure_loaded?(Ecto.Adapters.SQL.Sandbox) &&
                   Code.ensure_loaded?(Phoenix.Ecto.SQL.Sandbox)

  defmacro __using__(_) do
    quote do
      ExUnit.Case.register_attribute(__MODULE__, :sessions)

      use Wallaby.DSL
      import Wallaby.Feature

      setup context do
        metadata = configure_ecto(unquote(@includes_ecto), context[:async])

        start_session_opts =
          [metadata: metadata]
          |> put_create_session_fn(context[:create_session_fn])

        sessions =
          get_in(context, [:registered, :sessions])
          |> sessions_iterable()
          |> Enum.map(&start_session(&1, start_session_opts))

        sessions |> build_setup_return()
      end
    end
  end

  @doc false
  def build_setup_return([session] = sessions) when length(sessions) == 1 do
    [session: session]
  end

  def build_setup_return(sessions) do
    [sessions: sessions]
  end

  @doc false
  def sessions_iterable(nil), do: 1..1
  def sessions_iterable(count) when is_number(count), do: 1..count
  def sessions_iterable(capabilities) when is_list(capabilities), do: capabilities

  @doc false
  def start_session(more_opts, start_session_opts) when is_list(more_opts) do
    {:ok, session} =
      start_session_opts
      |> Keyword.merge(more_opts)
      |> Wallaby.start_session()

    session
  end

  def start_session(num, start_session_opts) when is_number(num) do
    {:ok, session} = Wallaby.start_session(start_session_opts)

    session
  end

  @doc false
  def put_create_session_fn(opts, nil), do: opts
  def put_create_session_fn(opts, func), do: Keyword.put(opts, :create_session_fn, func)

  if @includes_ecto do
    @doc false
    def otp_app(), do: Application.get_env(:wallaby, :otp_app)
    @doc false
    def ecto_repos(nil), do: []
    def ecto_repos(otp_app), do: Application.get_env(otp_app, :ecto_repos, [])

    @doc false
    def checkout_ecto_repos(repo, async) do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)

      unless async, do: Ecto.Adapters.SQL.Sandbox.mode(repo, {:shared, self()})

      repo
    end

    @doc false
    def metadata_for_ecto_repos([]), do: Map.new()

    def metadata_for_ecto_repos(repos) do
      Phoenix.Ecto.SQL.Sandbox.metadata_for(repos, self())
    end
  end

  @doc false
  defmacro configure_ecto(includes_ecto?, async?) do
    if includes_ecto? do
      quote do
        otp_app()
        |> ecto_repos()
        |> Enum.map(&checkout_ecto_repos(&1, unquote(async?)))
        |> metadata_for_ecto_repos()
      end
    else
      quote do
        ""
      end
    end
  end

  @doc """
  Defines a feature with a message.

  Adding `import Wallaby.Feature` to your test module will import the `Wallaby.Feature.feature/3` macro. This is a drop in replacement for the `ExUnit.Case.test/3` macro that you normally use.

  Adding `use Wallaby.Feature` to your test module will act the same as `import Wallaby.Feature`, as well as configure your Ecto repos properly and pass a `Wallaby.Session` into the test context.

  ## Sessions

  When called with `use`, the `Wallaby.Feature.feature/3` macro will automatically start a single session using the currently configured capabilities and is passed to the feature via the `:session` key in the context.

  ```
  feature "test with a single session", %{session: session} do
    # ...
  end
  ```

  If you would like to start multiple sessions, assign the `@sessions` attribute to the number of sessions that the feature should start, and they will be pass to the feature via the `:sessions` key in the context.

  ```
  @sessions 2
  feature "test with a two sessions", %{sessions: [session_1, sessions_2]} do
    # ...
  end
  ```

  If you need to change the capabilities sent to the session for a specific feature, you can assign `@sessions` to a list of keyword lists of the options to be passed to `Wallaby.start_session/1`. This will start the number of sessions equal to the size of the list.

  ```
  @sessions [
    [capabilities: %{}]
  ]
  feature "test with different capabilities", %{session: session} do
    # ...
  end
  ```

  If you don't wish to `use Wallaby.Feature` in your test module, you can add the following code to configure Ecto and create a session.

  ```
  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(YourApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(YourApp.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(YourApp.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)

    {:ok, session: session}
  end
  ```

  ## Screenshots

  If you have configured `screenshot_on_failure` to be true, any exceptions raised during the feature will trigger a screenshot to be taken.
  """

  defmacro feature(message, context \\ quote(do: _), contents) do
    contents =
      quote do
        try do
          unquote(contents)
          :ok
        rescue
          e ->
            if Wallaby.screenshot_on_failure?() do
              unquote(__MODULE__).take_screenshots_for_sessions(self(), unquote(message))
            end

            reraise(e, __STACKTRACE__)
        end
      end

    context = Macro.escape(context)
    contents = Macro.escape(contents, unquote: true)

    quote bind_quoted: [context: context, contents: contents, message: message] do
      name = ExUnit.Case.register_test(__ENV__, :feature, message, [:feature])

      def unquote(name)(unquote(context)), do: unquote(contents)
    end
  end

  @doc false
  def take_screenshots_for_sessions(pid, test_name) do
    time = :erlang.system_time(:second) |> to_string()
    test_name = String.replace(test_name, " ", "_")

    screenshot_paths =
      Wallaby.SessionStore.list_sessions_for(pid)
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {s, i} ->
        filename = time <> "_" <> test_name <> "(#{i})"

        Wallaby.Browser.take_screenshot(s, name: filename).screenshots
      end)
      |> Enum.map(&Wallaby.Browser.build_file_url/1)

    IO.write("\n- #{Enum.join(screenshot_paths, "\n- ")}")
  end
end
