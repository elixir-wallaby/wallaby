defmodule Wallaby.Experimental.Chrome do
  @behaviour Wallaby.Driver

  alias Wallaby.Session
  alias Wallaby.Experimental.Chrome.Webdriver
  # alias Wallaby.Phantom.Driver
  alias Wallaby.Experimental.Selenium.WebdriverClient


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

  def end_session(session, opts\\[]) do
    end_session_fn = Keyword.get(opts, :end_session_fn, &WebdriverClient.delete_session/1)
    end_session_fn.(session)
    :ok
  end

  def blank_page?(session) do
    current_url!(session) == "data:,"
  end

  def get_window_size(%Session{} = session) do
    handle = WebdriverClient.window_handle(session)
    WebdriverClient.get_window_size(session, handle)
    # WebdriverClient.get_window_size(session)
  end

  def set_window_size(session, width, height) do
    handles = WebdriverClient.window_handles(session)
    IO.inspect(handles, label: "Window handles")
    handle = WebdriverClient.window_handle(session)
    WebdriverClient.set_window_size(session, handle, width, height)
    # WebdriverClient.set_window_size(session, width, height)
  end

  @doc false
  defdelegate accept_dialogs(session),                            to: WebdriverClient
  @doc false
  defdelegate accept_alert(session, open_dialog_fn),              to: WebdriverClient
  @doc false
  defdelegate accept_confirm(session, open_dialog_fn),            to: WebdriverClient
  @doc false
  defdelegate accept_prompt(session, input_va, open_dialog_fn),   to: WebdriverClient
  @doc false
  defdelegate cookies(session),                                   to: WebdriverClient
  @doc false
  defdelegate current_path!(session),                             to: WebdriverClient
  @doc false
  defdelegate current_url!(session),                              to: WebdriverClient
  @doc false
  defdelegate dismiss_dialogs(session),                           to: WebdriverClient
  @doc false
  defdelegate dismiss_confirm(session, open_dialog_fn),           to: WebdriverClient
  @doc false
  defdelegate dismiss_prompt(session, open_dialog_fn),            to: WebdriverClient
  @doc false
  defdelegate page_title(session),                                to: WebdriverClient
  @doc false
  defdelegate page_source(session),                               to: WebdriverClient
  @doc false
  defdelegate set_cookie(session, key, value),                   to: WebdriverClient
  @doc false
  defdelegate visit(session, url),                                to: WebdriverClient

  @doc false
  defdelegate attribute(element, name),                           to: WebdriverClient
  @doc false
  defdelegate click(element),                                     to: WebdriverClient
  @doc false
  defdelegate clear(element),                                     to: WebdriverClient
  @doc false
  defdelegate displayed(element),                                 to: WebdriverClient
  @doc false
  defdelegate selected(element),                                  to: WebdriverClient
  @doc false
  defdelegate set_value(element, value),                          to: WebdriverClient
  @doc false
  defdelegate text(element),                                      to: WebdriverClient

  @doc false
  defdelegate execute_script(session_or_element, script, args),   to: WebdriverClient
  @doc false
  defdelegate find_elements(session_or_element, compiled_query),  to: WebdriverClient
  @doc false
  defdelegate send_keys(session_or_element, keys),                to: WebdriverClient
  @doc false
  defdelegate take_screenshot(session_or_element),                to: WebdriverClient

  @doc false
  def user_agent do
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
  end

  defp default_capabilities do
    %{
      javascriptEnabled: true,
      loadImages: false,
      version: "",
      rotatable: false,
      takesScreenshot: true,
      cssSelectorsEnabled: true,
      browserName: "phantomjs",
      nativeEvents: false,
      platform: "ANY",
      # chrome: %{
        chromeOptions: %{
          binary: "/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary",
          args: [
            "--no-sandbox",
            # "start-fullscreen",
            "window-size=1280,800",
            # "--headless",
            "--disable-gpu"
          ]
        }
      # }
    }
  end


end
