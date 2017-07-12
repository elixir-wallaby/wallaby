defmodule Wallaby.Experimental.Selenium do
  @moduledoc false

  @behaviour Wallaby.Driver

  alias Wallaby.{Driver, Element, Session}
  alias Wallaby.Experimental.Selenium.WebdriverClient

  @type start_session_opts ::
    {:remote_url, String.t} |
    {:capabilities, map} |
    {:create_session_fn, ((String.t, map) -> {:ok, %{}})}

  @spec start_session([start_session_opts]) :: {:ok, Session.t}
  def start_session(opts \\ []) do
    base_url = Keyword.get(opts, :remote_url, "http://localhost:4444/wd/hub/")
    capabilities = Keyword.get(opts, :capabilities, %{})
    create_session_fn = Keyword.get(opts, :create_session_fn,
                                    &WebdriverClient.create_session/2)

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

  @type end_session_opts ::
    {:end_session_fn, ((Session.t) -> any)}

  @doc """
  Invoked to end a browser session.
  """
  @spec end_session(Session.t, [end_session_opts]) :: :ok
  def end_session(session, opts \\ []) do
    end_session_fn =
      Keyword.get(opts, :end_session_fn, &WebdriverClient.delete_session/1)

    end_session_fn.(session)
    :ok
  end

  # Dialog handling not supported yet
  def accept_dialogs(_session), do: {:error, :not_implemented}
  def dismiss_dialogs(_session), do: {:error, :not_implemented}
  def accept_alert(_session, _fun), do: {:error, :not_implemented}
  def dismiss_alert(_session, _fun), do: {:error, :not_implemented}
  def accept_confirm(_session, _fun), do: {:error, :not_implemented}
  def dismiss_confirm(_session, _fun), do: {:error, :not_implemented}
  def accept_prompt(_session, _input, _fun), do: {:error, :not_implemented}
  def dismiss_prompt(_session, _fun), do: {:error, :not_implemented}

  # Screenshots don't appear to be supported with Gecko Driver
  def take_screenshot(_session), do: {:error, :not_supported}

  def cookies(%Session{} = session) do
    WebdriverClient.cookies(session)
  end

  def current_path!(%Session{} = session) do
    session
    |> WebdriverClient.current_url!
    |> URI.parse
    |> Map.get(:path)
  end

  def current_url!(%Session{} = session) do
    WebdriverClient.current_url!(session)
  end

  def get_window_size(%Session{} = session) do
    handle = WebdriverClient.window_handle(session)
    WebdriverClient.get_window_size(session, handle)
  end

  def page_source(%Session{} = session) do
    WebdriverClient.page_source(session)
  end

  def page_title(%Session{} = session) do
    WebdriverClient.page_title(session)
  end

  def set_cookie(%Session{} = session, key, value) do
    WebdriverClient.set_cookie(session, key, value)
  end

  def set_window_size(%Session{} = session, width, height) do
    handle = WebdriverClient.window_handle(session)
    WebdriverClient.set_window_size(session, handle, width, height)
  end

  def visit(%Session{} = session, path) do
    WebdriverClient.visit(session, path)
  end

  def attribute(%Element{} = element, name) do
    WebdriverClient.attribute(element, name)
  end

  @spec clear(Element.t) :: {:ok, nil} | {:error, Driver.reason}
  def clear(%Element{} = element) do
    WebdriverClient.clear(element)
  end

  def click(%Element{} = element) do
    WebdriverClient.click(element)
  end

  def displayed(%Element{} = element) do
    WebdriverClient.displayed(element)
  end

  def selected(%Element{} = element) do
    WebdriverClient.selected(element)
  end

  @spec set_value(Element.t, String.t) :: {:ok, nil} | {:error, Driver.reason}
  def set_value(%Element{} = element, value) do
    WebdriverClient.set_value(element, value)
  end

  def text(%Element{} = element) do
    WebdriverClient.text(element)
  end

  def find_elements(parent, compiled_query) do
    WebdriverClient.find_elements(parent, compiled_query)
  end

  def execute_script(parent, script, arguments \\ []) do
    WebdriverClient.execute_script(parent, script, arguments)
  end

  def send_keys(parent, keys) do
    WebdriverClient.send_keys(parent, keys)
  end

  defp default_capabilities do
    %{
      javascriptEnabled: true
    }
  end
end
