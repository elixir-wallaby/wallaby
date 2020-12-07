defmodule Wallaby.Selenium do
  @moduledoc """
  The Selenium driver uses [Selenium Server](https://github.com/SeleniumHQ/selenium) to power many types of browsers (Chrome, Firefox, Edge, etc).

  ## Usage

  Start a Wallaby Session using this driver with the following command:

  ```
  {:ok, session} = Wallaby.start_session()
  ```

  ## Configuration

  ### Capabilities

  These capabilities will override the default capabilities.

  ```
  config :wallaby,
    selenium: [
      capabilities: %{
        # something
      }
    ]
  ```

  ## Default Capabilities

  By default, Selenium will use the following capabilities

  You can read more about capabilities in the [JSON Wire Protocol](https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#capabilities-json-object) documentation.

  ```elixir
  %{
    javascriptEnabled: true,
    browserName: "firefox",
    "moz:firefoxOptions": %{
      args: ["-headless"]
    }
  }
  ```

  ## Notes

  - Requires [selenium-server-standalone](https://www.seleniumhq.org/download/) to be running on port 4444. Wallaby does _not_ manage the start/stop of the Selenium server.
  - Requires [GeckoDriver](https://github.com/mozilla/geckodriver) to be installed in your path when using [Firefox](https://www.mozilla.org/en-US/firefox/new/). Firefox is used by default.
  """

  use Supervisor

  @behaviour Wallaby.Driver

  alias Wallaby.{Driver, Element, Session}
  alias Wallaby.Helpers.KeyCodes
  alias Wallaby.WebdriverClient

  @typedoc """
  Options to pass to Wallaby.start_session/1

  ```elixir
  Wallaby.start_session(
    remote_url: "http://selenium_url",
    capabilities: %{browserName: "firefox"}
  )
  ```
  """
  @type start_session_opts ::
          {:remote_url, String.t()}
          | {:capabilities, map}

  @doc false
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc false
  def init(_) do
    Supervisor.init([], strategy: :one_for_one)
  end

  @doc false
  def validate do
    :ok
  end

  @doc false
  @spec start_session([start_session_opts]) :: Wallaby.Driver.on_start_session() | no_return
  def start_session(opts \\ []) do
    base_url = Keyword.get(opts, :remote_url, "http://localhost:4444/wd/hub/")
    capabilities = Keyword.get(opts, :capabilities, capabilities_from_config())

    with {:ok, response} <- WebdriverClient.create_session(base_url, capabilities) do
      id = response["sessionId"]

      session = %Session{
        session_url: base_url <> "session/#{id}",
        url: base_url <> "session/#{id}",
        id: id,
        driver: __MODULE__,
        capabilities: capabilities
      }

      if window_size = Keyword.get(opts, :window_size),
        do: {:ok, _} = set_window_size(session, window_size[:width], window_size[:height])

      {:ok, session}
    end
  end

  defp capabilities_from_config() do
    :wallaby
    |> Application.get_env(:selenium, [])
    |> Keyword.get(:capabilities, default_capabilities())
  end

  @doc false
  @spec end_session(Session.t()) :: :ok
  def end_session(session) do
    WebdriverClient.delete_session(session)
    :ok
  end

  @doc false
  def blank_page?(session) do
    case current_url(session) do
      {:ok, url} ->
        url == "about:blank"

      _ ->
        false
    end
  end

  @doc false
  defdelegate window_handle(session), to: WebdriverClient
  @doc false
  defdelegate window_handles(session), to: WebdriverClient
  @doc false
  defdelegate focus_window(session, window_handle), to: WebdriverClient
  @doc false
  defdelegate close_window(session), to: WebdriverClient
  @doc false
  defdelegate get_window_size(session), to: WebdriverClient
  @doc false
  defdelegate set_window_size(session, width, height), to: WebdriverClient
  @doc false
  defdelegate get_window_position(session), to: WebdriverClient
  @doc false
  defdelegate set_window_position(session, x, y), to: WebdriverClient
  @doc false
  defdelegate maximize_window(session), to: WebdriverClient

  @doc false
  defdelegate focus_frame(session, frame), to: WebdriverClient
  @doc false
  defdelegate focus_parent_frame(session), to: WebdriverClient

  @doc false
  defdelegate accept_alert(session, fun), to: WebdriverClient
  @doc false
  defdelegate dismiss_alert(session, fun), to: WebdriverClient
  @doc false
  defdelegate accept_confirm(session, fun), to: WebdriverClient
  @doc false
  defdelegate dismiss_confirm(session, fun), to: WebdriverClient
  @doc false
  defdelegate accept_prompt(session, input, fun), to: WebdriverClient
  @doc false
  defdelegate dismiss_prompt(session, fun), to: WebdriverClient

  @doc false
  defdelegate take_screenshot(session_or_element), to: WebdriverClient

  @doc false
  def cookies(%Session{} = session) do
    WebdriverClient.cookies(session)
  end

  @doc false
  def current_path(%Session{} = session) do
    with {:ok, url} <- WebdriverClient.current_url(session),
         uri <- URI.parse(url),
         {:ok, path} <- Map.fetch(uri, :path),
         do: {:ok, path}
  end

  @doc false
  def current_url(%Session{} = session) do
    WebdriverClient.current_url(session)
  end

  @doc false
  def page_source(%Session{} = session) do
    WebdriverClient.page_source(session)
  end

  @doc false
  def page_title(%Session{} = session) do
    WebdriverClient.page_title(session)
  end

  @doc false
  def set_cookie(%Session{} = session, key, value) do
    WebdriverClient.set_cookie(session, key, value)
  end

  @doc false
  def visit(%Session{} = session, path) do
    WebdriverClient.visit(session, path)
  end

  @doc false
  def attribute(%Element{} = element, name) do
    WebdriverClient.attribute(element, name)
  end

  @doc false
  @spec clear(Element.t()) :: {:ok, nil} | {:error, Driver.reason()}
  def clear(%Element{} = element) do
    WebdriverClient.clear(element)
  end

  @doc false
  def click(%Element{} = element) do
    WebdriverClient.click(element)
  end

  @doc false
  def click(parent, button) do
    WebdriverClient.click(parent, button)
  end

  @doc false
  def button_down(parent, button) do
    WebdriverClient.button_down(parent, button)
  end

  @doc false
  def button_up(parent, button) do
    WebdriverClient.button_up(parent, button)
  end

  @doc false
  def double_click(parent) do
    WebdriverClient.double_click(parent)
  end

  @doc false
  def hover(%Element{} = element) do
    WebdriverClient.move_mouse_to(nil, element)
  end

  @doc false
  def move_mouse_by(session, x_offset, y_offset) do
    WebdriverClient.move_mouse_to(session, nil, x_offset, y_offset)
  end

  @doc false
  def displayed(%Element{} = element) do
    WebdriverClient.displayed(element)
  end

  @doc false
  def selected(%Element{} = element) do
    WebdriverClient.selected(element)
  end

  @doc false
  @spec set_value(Element.t(), String.t()) :: {:ok, nil} | {:error, Driver.reason()}
  def set_value(%Element{} = element, value) do
    WebdriverClient.set_value(element, value)
  end

  @doc false
  def text(%Element{} = element) do
    WebdriverClient.text(element)
  end

  @doc false
  def find_elements(parent, compiled_query) do
    WebdriverClient.find_elements(parent, compiled_query)
  end

  @doc false
  def execute_script(parent, script, arguments \\ []) do
    WebdriverClient.execute_script(parent, script, arguments)
  end

  @doc false
  def execute_script_async(parent, script, arguments \\ []) do
    WebdriverClient.execute_script_async(parent, script, arguments)
  end

  @doc """
  Simulates typing into an element.

  When sending keys to an element and `keys` is identified as
  a local file, the local file is uploaded to the
  Selenium server, returning a file path which is then
  set to the file input we are interacting with.

  We then call the `WebdriverClient.send_keys/2` to set the
  remote file path as the input's value.
  """
  @spec send_keys(Session.t() | Element.t(), list()) :: {:ok, any}
  def send_keys(%Session{} = session, keys), do: WebdriverClient.send_keys(session, keys)

  def send_keys(%Element{} = element, keys) do
    keys =
      case Enum.all?(keys, &is_local_file?(&1)) do
        true ->
          keys
          |> Enum.map(fn key -> upload_file(element, key) end)
          |> Enum.intersperse("\n")

        false ->
          keys
      end

    WebdriverClient.send_keys(element, keys)
  end

  def element_size(element) do
    WebdriverClient.element_size(element)
  end

  def element_location(element) do
    WebdriverClient.element_location(element)
  end

  @doc false
  def default_capabilities do
    %{
      javascriptEnabled: true,
      browserName: "firefox",
      "moz:firefoxOptions": %{
        args: ["-headless"]
      }
    }
  end

  # Create a zip file containing our local file
  defp create_zipfile(zipfile, filename) do
    {:ok, ^zipfile} =
      :zip.create(
        zipfile,
        [String.to_charlist(Path.basename(filename))],
        cwd: String.to_charlist(Path.dirname(filename))
      )

    zipfile
  end

  # Base64 encode the zipfile for transfer to remote Selenium
  defp encode_zipfile(zipfile) do
    File.open!(zipfile, [:read, :raw], fn f ->
      f
      |> IO.binread(:all)
      |> Base.encode64()
    end)
  end

  defp is_local_file?(file) do
    file
    |> keys_to_binary()
    |> File.exists?()
  end

  defp keys_to_binary(keys) do
    keys
    |> KeyCodes.chars()
    |> IO.iodata_to_binary()
  end

  # Makes an uploadable file for JSONWireProtocol
  defp make_file(filename) do
    System.tmp_dir!()
    |> Path.join("#{random_filename()}.zip")
    |> String.to_charlist()
    |> create_zipfile(filename)
    |> encode_zipfile()
  end

  # Generate a random filename
  defp random_filename do
    Base.encode32(:crypto.strong_rand_bytes(20))
  end

  # Uploads a local file to remote Selenium server
  # Returns the remote file's uploaded location
  defp upload_file(element, filename) do
    zip64 = make_file(filename)
    endpoint = element.session_url <> "/file"

    with {:ok, response} <- Wallaby.HTTPClient.request(:post, endpoint, %{file: zip64}) do
      Map.fetch!(response, "value")
    end
  end
end
