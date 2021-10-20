defmodule Wallaby.BrowserTest do
  use ExUnit.Case

  import Wallaby.SettingsTestHelpers

  alias Wallaby.Browser
  alias Wallaby.NoBaseUrlError
  alias Wallaby.Session

  defmodule TestDriver do
    use Agent

    def start_link(_opts) do
      Agent.start_link(fn -> [] end, name: __MODULE__)
    end

    def visit(%Session{} = session, path) do
      Agent.update(__MODULE__, fn visits ->
        [path | visits]
      end)

      session
    end

    def assert_visited(url) do
      unless Enum.member?(visits(), url) do
        raise ExUnit.AssertionError,
              """
              #{inspect(url)} was not visited.

              Visited urls:
              #{visits() |> Enum.map_join("\n", fn v -> "  #{inspect(v)}" end)}
              """
      end
    end

    defp visits do
      Agent.get(__MODULE__, fn visits -> visits end)
    end
  end

  describe "visit/2" do
    setup do
      ensure_setting_is_reset(:wallaby, :base_url)
      start_supervised!(TestDriver)
      :ok
    end

    test "relative path without leading slash, base url with trailing slash" do
      Application.put_env(:wallaby, :base_url, "http://example.com/")

      session = session_for_driver(TestDriver)
      Browser.visit(session, "form.html")

      TestDriver.assert_visited("http://example.com/form.html")
    end

    test "relative path with leading slash, base url no trailing slash" do
      Application.put_env(:wallaby, :base_url, "http://example.com")

      session = session_for_driver(TestDriver)
      Browser.visit(session, "/form.html")

      TestDriver.assert_visited("http://example.com/form.html")
    end

    test "relative path without leading slash, base url no trailing slash" do
      Application.put_env(:wallaby, :base_url, "http://example.com")

      session = session_for_driver(TestDriver)
      Browser.visit(session, "form.html")

      TestDriver.assert_visited("http://example.com/form.html")
    end

    test "relative path with leading slash, base url trailing slash" do
      Application.put_env(:wallaby, :base_url, "http://example.com/")

      session = session_for_driver(TestDriver)
      Browser.visit(session, "/form.html")

      TestDriver.assert_visited("http://example.com/form.html")
    end

    test "relative path with leading slash, base url ending in /api" do
      Application.put_env(:wallaby, :base_url, "https://example.com:9090/api/")

      session = session_for_driver(TestDriver)
      Browser.visit(session, "/form.html?something=2")

      TestDriver.assert_visited("https://example.com:9090/api/form.html?something=2")
    end

    test "relative url when the base_url isn't configured" do
      Application.delete_env(:wallaby, :base_url)

      assert_raise NoBaseUrlError, fn ->
        session = session_for_driver(TestDriver)
        Browser.visit(session, "/form.html")
      end
    end

    test "absolute url when the base_url isn't configured" do
      Application.delete_env(:wallaby, :base_url)
      uri = "https://example.com:9090/api/form.html"

      session = session_for_driver(TestDriver)
      Browser.visit(session, uri)

      TestDriver.assert_visited(uri)
    end

    test "absolute url when the base_url is configured" do
      Application.put_env(:wallaby, :base_url, "http://example.org:5555/test")
      uri = "https://example.com:9090/api/form.html"

      session = session_for_driver(TestDriver)
      Browser.visit(session, uri)

      TestDriver.assert_visited(uri)
    end
  end

  describe "retry/2" do
    test "returns a valid result" do
      assert Browser.retry(fn -> {:ok, []} end) == {:ok, []}
    end

    test "it retries if the dom element is stale" do
      {:ok, agent} = Agent.start_link(fn -> {:error, :stale_reference} end)

      run_query = fn ->
        Agent.get_and_update(agent, fn initial ->
          {initial, {:ok, []}}
        end)
      end

      assert Browser.retry(run_query)
    end

    test "it retries until time runs out" do
      assert Browser.retry(fn -> {:error, :some_error} end) == {:error, :some_error}
    end
  end

  defp session_for_driver(driver) do
    %Session{driver: driver}
  end
end
