defmodule Wallaby.Experimental.Chrome do
  alias Wallaby.Session
  alias Wallaby.Experimental.Chrome.Webdriver

  def start_session(opts \\ []) do
    base_url = Keyword.get(opts, :remote_url, "http://localhost:9515/")
    capabilities = Keyword.get(opts, :capabilities, %{})
    create_session_fn = Keyword.get(opts, :create_session_fn,
                                    &Webdriver.create_session/2)

    capabilities = Map.merge(default_capabilities(), capabilities)

    with {:ok, response} <- create_session_fn.(base_url, capabilities) do
      id = response["sessionId"]

      session = %Wallaby.Session{
        session_url: base_url <> "session/#{id}",
        url: base_url <> "session/#{id}",
        id: id,
        driver: __MODULE__
      }

      {:ok, session}
    end
  end

  defp default_capabilities do
    %{
      javascriptEnabled: true,
      # chrome: %{
        chromeOptions: %{
          binary: "/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary",
          args: [
            "--headless",
            "--disable-gpu",
            # "--remote-debugging-port=9222",
            "localhost:5000"
          ]
        }
      # }
    }
  end
end
