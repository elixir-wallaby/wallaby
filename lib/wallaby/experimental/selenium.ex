defmodule Wallaby.Experimental.Selenium do
  @moduledoc false
  use Supervisor

  @behaviour Wallaby.Driver

  alias Wallaby.{Driver, Element, Session}
  alias Wallaby.Experimental.Selenium.WebdriverClient

  @type start_session_opts ::
    {:remote_url, String.t} |
    {:capabilities, map} |
    {:create_session_fn, ((String.t, map) -> {:ok, %{}})}

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
    ]

    supervise(children, strategy: :one_for_one)
  end

  def validate do
    :ok
  end

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

      if window_size = Keyword.get(opts, :window_size),
        do: {:ok, _} = set_window_size(session, window_size[:width], window_size[:height])

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

  def blank_page?(session) do
    case current_url(session) do
      {:ok, url} ->
        url == "about:blank"
      _ ->
        false
    end
  end

  defdelegate window_handle(session), to: WebdriverClient
  defdelegate window_handles(session), to: WebdriverClient
  defdelegate focus_window(session, window_handle), to: WebdriverClient
  defdelegate close_window(session), to: WebdriverClient
  defdelegate get_window_size(session), to: WebdriverClient
  defdelegate set_window_size(session, width, height), to: WebdriverClient
  defdelegate get_window_position(session), to: WebdriverClient
  defdelegate set_window_position(session, x, y), to: WebdriverClient
  defdelegate maximize_window(session), to: WebdriverClient

  defdelegate focus_frame(session, frame), to: WebdriverClient
  defdelegate focus_parent_frame(session), to: WebdriverClient

  defdelegate accept_alert(session, fun), to: WebdriverClient
  defdelegate dismiss_alert(session, fun), to: WebdriverClient
  defdelegate accept_confirm(session, fun), to: WebdriverClient
  defdelegate dismiss_confirm(session, fun), to: WebdriverClient
  defdelegate accept_prompt(session, input, fun), to: WebdriverClient
  defdelegate dismiss_prompt(session, fun), to: WebdriverClient

  defdelegate take_screenshot(session_or_element), to: WebdriverClient

  def cookies(%Session{} = session) do
    WebdriverClient.cookies(session)
  end

  def current_path(%Session{} = session) do
    with  {:ok, url} <- WebdriverClient.current_url(session),
          uri <- URI.parse(url),
          {:ok, path} <- Map.fetch(uri, :path),
      do: {:ok, path}
  end

  def current_url(%Session{} = session) do
    WebdriverClient.current_url(session)
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

  # TODO: make it working for Selenium, now it doesn't work for middle and right mouse button
  # def click(parent, button) do
  #   WebdriverClient.click(parent, button)
  # end

  def hover(%Element{} = element) do
    WebdriverClient.move_to(nil, element)
  end

  def move_by(session, x_offset, y_offset) do
    WebdriverClient.move_to(session, nil, x_offset, y_offset)
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

  def execute_script_async(parent, script, arguments \\ []) do
    WebdriverClient.execute_script_async(parent, script, arguments)
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
