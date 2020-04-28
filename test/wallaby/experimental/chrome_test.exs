defmodule Wallaby.Experimental.ChromeTest do
  use Wallaby.HttpClientCase, async: true

  alias Wallaby.Experimental.Chrome

  describe "start_session" do
    test "checks out a chrome instance from the pool" do
      config = [
        name: {:local, :chrome_instances},
        worker_module: Wallaby.Experimental.Chrome.Chromedriver.Server,
        size: 2,
        max_overflow: 0
      ]

      {:ok, chromedriver_path} = Chrome.find_chromedriver_executable()

      child_spec =
        :poolboy.child_spec(:chrome_instances, config, chromedriver_path)
        |> from_deprecated_child_spec()

      start_supervised!(child_spec)

      {:ok, session} = Chrome.start_session()

      assert is_pid(session.server)
    end
  end

  defp from_deprecated_child_spec({child_id, start_mfa, restart, shutdown, worker, modules}) do
    %{
      id: child_id,
      start: start_mfa,
      restart: restart,
      shutdown: shutdown,
      worker: worker,
      modules: modules
    }
  end
end
