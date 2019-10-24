defmodule Wallaby.FeatureCase do
  @moduledoc """
  TODO
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      ExUnit.Case.register_attribute(__MODULE__, :sessions)

      use Wallaby.DSL
      import Wallaby.FeatureCase
    end
  end

  setup context do
    metadata =
      otp_app()
      |> ecto_repos()
      |> Enum.map(&checkout_ecto_repos(&1, context[:async]))
      |> metadata_for_ecto_repos()

    start_session_opts =
      [metadata: metadata]
      |> put_create_session_fn(context[:create_session_fn])

    sessions =
      get_in(context, [:registered, :sessions])
      |> sessions_iterable()
      |> Enum.map(&start_session(&1, start_session_opts))

    [sessions: sessions]
  end

  defp sessions_iterable(nil), do: 1..1
  defp sessions_iterable(count) when is_number(count), do: 1..count
  defp sessions_iterable(capabilities) when is_list(capabilities), do: capabilities

  defp start_session(more_opts, start_session_opts) when is_list(more_opts) do
    {:ok, session} =
      start_session_opts
      |> Keyword.merge(more_opts)
      |> Wallaby.start_session()

    session
  end

  defp start_session(num, start_session_opts) when is_number(num) do
    {:ok, session} = Wallaby.start_session(start_session_opts)

    session
  end

  defp put_create_session_fn(opts, nil), do: opts
  defp put_create_session_fn(opts, func), do: Keyword.put(opts, :create_session_fn, func)

  defp otp_app(), do: Application.get_env(:wallaby, :otp_app)
  defp ecto_repos(nil), do: []
  defp ecto_repos(otp_app), do: Application.get_env(otp_app, :ecto_repos, [])

  defp checkout_ecto_repos(repo, async) do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)

    unless async, do: Ecto.Adapters.SQL.Sandbox.mode(repo, {:shared, self()})

    repo
  end

  def metadata_for_ecto_repos([]), do: Map.new()
  def metadata_for_ecto_repos(repos), do: Phoenix.Ecto.SQL.Sandbox.metadata_for(repos, self())

  defmacro feature(test_name, context \\ quote(do: _), contents) do
    contents =
      quote do
        try do
          unquote(contents)
          :ok
        rescue
          e ->
            if Wallaby.screenshot_on_failure?() do
              Wallaby.FeatureCase.__take_screenshot__(unquote_splicing([context, test_name]))
            end

            reraise(e, __STACKTRACE__)
        end
      end

    context = Macro.escape(context)
    contents = Macro.escape(contents, unquote: true)

    quote bind_quoted: [context: context, contents: contents, test_name: test_name] do
      name = ExUnit.Case.register_test(__ENV__, :feature, test_name, [:feature])

      def unquote(name)(unquote(context)), do: unquote(contents)
    end
  end

  @doc false
  def __take_screenshot__(context, test_name) do
    time = :erlang.system_time() |> to_string()
    test_name = String.replace(test_name, " ", "_")

    context
    |> Map.fetch!(:sessions)
    |> Enum.with_index()
    |> Enum.each(fn {s, i} ->
      filename = time <> "_" <> test_name <> "(#{i + 1})"

      Wallaby.Browser.take_screenshot(s, name: filename, log: true)
    end)
  end
end
