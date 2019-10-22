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
    sessions_count = get_in(context, [:registered, :sessions]) || 1

    metadata =
      otp_app()
      |> ecto_repos()
      |> Enum.map(&checkout_ecto_repos(&1, context[:async]))
      |> metadata_for_ecto_repos()

    sessions =
      1..sessions_count
      |> Enum.map(fn _ ->
        context = String.replace(to_string(context.test), " ", "_")

        {:ok, session} =
          Wallaby.start_session(context: context, metadata: metadata)

        session
      end)

    [sessions: sessions]
  end

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

  defmacro feature(message, context \\ quote(do: _), contents) do
    contents =
      quote do
        try do
          unquote(contents)
          :ok
        rescue
          e ->
            if Wallaby.screenshot_on_failure?(),
              do: Wallaby.FeatureCase.__take_screenshot__(unquote(context))

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
  def __take_screenshot__(context) do
    time = :erlang.system_time() |> to_string()

    context
    |> Map.fetch!(:sessions)
    |> Enum.with_index()
    |> Enum.each(fn {s, i} ->
      filename = time <> "_" <> s.context <> "(#{i + 1})"

      Wallaby.Browser.take_screenshot(s, name: filename, log: true)
    end)
  end
end
