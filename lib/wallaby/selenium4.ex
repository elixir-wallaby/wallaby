defmodule Wallaby.Selenium4 do
  @moduledoc """
  The Selenium driver uses [Selenium Server](https://github.com/SeleniumHQ/selenium) to power many types of browsers (Chrome, Firefox, Edge, etc).

  ## Usage

  Start a Wallaby Session using this driver with the following command:

  ```elixir
  {:ok, session} = Wallaby.start_session()
  ```

  ## Configuration

  ### Capabilities

  These capabilities will override the default capabilities.

  ```elixir
  config :wallaby,
    selenium4: [
      capabilities: %{
        # something
      }
    ]
  ```

  ### Selenium Remote URL

  It is possible to globally set Selenium's "Remote URL" by setting the following option.

  By default it is http://localhost:4444/wd/hub/

  ```elixir
  config :wallaby,
    selenium4: [
      remote_url: "http://selenium_url"
    ]
  ```

  ## Default Capabilities

  By default, Selenium will use the following capabilities

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

  - Requires [selenium-server](https://www.seleniumhq.org/download/) to be running on port 4444. Wallaby does _not_ manage the start/stop of the Selenium server.
  - Requires [GeckoDriver](https://github.com/mozilla/geckodriver) to be installed in your path when using [Firefox](https://www.mozilla.org/en-US/firefox/new/). Firefox is used by default.
  """

  use Supervisor

  @behaviour Wallaby.Driver

  alias Wallaby.Helpers.KeyCodes
  alias Wallaby.Metadata
  alias Wallaby.{Driver, Element, Session}

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
    base_url = Keyword.get(opts, :remote_url, remote_url_from_config())

    config =
      WebDriverClient.Config.build(base_url,
        protocol: :w3c,
        http_client_options: [hackney: [pool: :wallaby_pool]]
      )

    create_session = Keyword.get(opts, :create_session_fn, &WebDriverClient.start_session/2)

    capabilities =
      opts
      |> Keyword.get_lazy(:capabilities, &capabilities_from_config/0)
      |> put_beam_metadata(opts)

    with {:ok, wdc_session} <- create_session.(config, capabilities) do
      id = wdc_session.id

      session = %Session{
        session_url: base_url <> "session/#{id}",
        url: base_url <> "session/#{id}",
        id: id,
        driver: __MODULE__,
        capabilities: capabilities,
        wdc_config: config,
        wdc_session: wdc_session
      }

      if window_size = Keyword.get(opts, :window_size),
        do: {:ok, _} = set_window_size(session, window_size[:width], window_size[:height])

      {:ok, session}
    end
  end

  defp capabilities_from_config do
    :wallaby
    |> Application.get_env(:selenium4, [])
    |> Keyword.get_lazy(:capabilities, &default_capabilities/0)
  end

  defp remote_url_from_config() do
    :wallaby
    |> Application.get_env(:selenium4, [])
    |> Keyword.get(:remote_url, "http://localhost:4444/")
  end

  @doc false
  @spec end_session(Session.t()) :: :ok
  def end_session(session) do
    WebDriverClient.end_session(session)
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
  def window_handle(session) do
    WebDriverClient.fetch_window_handle(session.wdc_session)
  end

  def window_handles(session) do
    WebDriverClient.fetch_window_handles(session.wdc_session)
  end

  def focus_window(session, window_handle) do
    WebDriverClient.focus_window(session, window_handle)
  end

  def close_window(session) do
    WebDriverClient.close_window(session)
  end

  def get_window_size(session) do
    WebDriverClient.get_window_size(session)
  end

  def set_window_size(session, width, height) do
    WebDriverClient.set_window_size(session.wdc_session, width: width, height: height)
  end

  @doc false
  def get_window_position(session) do
    WebDriverClient.get_window_position(session)
  end

  def set_window_position(session, x, y) do
    WebDriverClient.set_window_position(session, x, y)
  end

  def maximize_window(session) do
    WebDriverClient.maximize_window(session)
  end

  def focus_frame(session, frame) do
    WebDriverClient.focus_frame(session, frame)
  end

  def focus_parent_frame(session) do
    WebDriverClient.focus_parent_frame(session)
  end

  def accept_alert(session, fun) do
    WebDriverClient.accept_alert(session, fun)
  end

  def dismiss_alert(session, fun) do
    WebDriverClient.dismiss_alert(session, fun)
  end

  def accept_confirm(session, fun) do
    WebDriverClient.accept_confirm(session, fun)
  end

  def dismiss_confirm(session, fun) do
    WebDriverClient.dismiss_confirm(session, fun)
  end

  def accept_prompt(session, input, fun) do
    WebDriverClient.accept_prompt(session, input, fun)
  end

  def dismiss_prompt(session, fun) do
    WebDriverClient.dismiss_prompt(session, fun)
  end

  def take_screenshot(session_or_element) do
    WebDriverClient.take_screenshot(session_or_element)
  end

  def cookies(%Session{} = session) do
    WebDriverClient.cookies(session)
  end

  @doc false
  def current_path(%Session{} = session) do
    with {:ok, url} <- WebDriverClient.current_url(session) do
      url
      |> URI.parse()
      |> Map.fetch(:path)
    end
  end

  @doc false
  def current_url(%Session{} = session) do
    WebDriverClient.current_url(session)
  end

  @doc false
  def page_source(%Session{} = session) do
    WebDriverClient.page_source(session)
  end

  @doc false
  def page_title(%Session{} = session) do
    WebDriverClient.page_title(session)
  end

  @doc false
  def set_cookie(%Session{} = session, key, value, attributes \\ []) do
    WebDriverClient.set_cookie(session, key, value, attributes)
  end

  @doc false
  def visit(%Session{} = session, path) do
    WebDriverClient.navigate_to(session.wdc_session, path)
  end

  @doc false
  def attribute(%Element{} = element, name) do
    WebDriverClient.attribute(element, name)
  end

  @doc false
  @spec clear(Element.t()) :: {:ok, nil} | {:error, Driver.reason()}
  def clear(%Element{} = element) do
    WebDriverClient.clear(element)
  end

  @doc false
  def click(%Element{} = element) do
    WebDriverClient.click_element(element)
  end

  @doc false
  def click(parent, button) do
    WebDriverClient.click_element(parent, button)
  end

  @doc false
  def button_down(parent, button) do
    WebDriverClient.button_down(parent, button)
  end

  @doc false
  def button_up(parent, button) do
    WebDriverClient.button_up(parent, button)
  end

  @doc false
  def double_click(parent) do
    WebDriverClient.double_click(parent)
  end

  @doc false
  def hover(%Element{} = element) do
    WebDriverClient.move_mouse_to(nil, element)
  end

  @doc false
  def move_mouse_by(session, x_offset, y_offset) do
    WebDriverClient.move_mouse_to(session, nil, x_offset, y_offset)
  end

  @doc false
  def displayed(%Element{} = element) do
    dbg(element)

    WebDriverClient.fetch_element_displayed(element.parent.wdc_session, %WebDriverClient.Element{
      id: element.id
    })
  end

  @doc false
  def selected(%Element{} = element) do
    WebDriverClient.selected(element)
  end

  @doc false
  @spec set_value(Element.t(), String.t()) :: {:ok, nil} | {:error, Driver.reason()}
  def set_value(%Element{} = element, value) do
    WebDriverClient.set_value(element, value)
  end

  @doc false
  def text(%Element{} = element) do
    WebDriverClient.text(element)
  end

  @doc false
  def find_elements(parent, compiled_query) do
    wdc_session =
      case parent do
        %Session{} -> parent.wdc_session
        %Element{session: session} -> session.wdc_session
      end

    {strategy, selector} =
      case compiled_query do
        {:css, selector} -> {:css_selector, selector}
        other -> other
      end

    with {:ok, elements} <- WebDriverClient.find_elements(wdc_session, strategy, selector) do
      {:ok, for(e <- elements, do: wdc_element_to_wallaby_element(parent, e))}
    end
  end

  @doc false
  def execute_script(parent, script, arguments \\ []) do
    WebDriverClient.execute_script(parent, script, arguments)
  end

  @doc false
  def execute_script_async(parent, script, arguments \\ []) do
    WebDriverClient.execute_script_async(parent, script, arguments)
  end

  @doc """
  Simulates typing into an element.

  When sending keys to an element and `keys` is identified as
  a local file, the local file is uploaded to the
  Selenium server, returning a file path which is then
  set to the file input we are interacting with.

  We then call the `WebDriverClient.send_keys/2` to set the
  remote file path as the input's value.
  """
  @spec send_keys(Session.t() | Element.t(), list()) :: {:ok, any}
  def send_keys(%Session{} = session, keys), do: WebDriverClient.send_keys(session, keys)

  def send_keys(%Element{} = element, keys) do
    keys =
      case Enum.all?(keys, &local_file?(&1)) do
        true ->
          keys |> Enum.map_intersperse("\n", fn key -> upload_file(element, key) end)

        false ->
          keys
      end

    WebDriverClient.send_keys(element, keys)
  end

  def element_size(element) do
    WebDriverClient.element_size(element)
  end

  def element_location(element) do
    WebDriverClient.element_location(element)
  end

  @doc false
  def default_capabilities do
    %{
      capabilities: %{
        alwaysMatch: %{
          browserName: "firefox",
          "moz:firefoxOptions": %{
            binary: System.find_executable("firefox"),
            args: ["-headless"],
            prefs: %{
              "general.useragent.override" =>
                "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
            }
          }
        }
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

  @binread_arg if Version.parse!(System.version()).minor >= 13, do: :eof, else: :all

  # Base64 encode the zipfile for transfer to remote Selenium
  defp encode_zipfile(zipfile) do
    File.open!(zipfile, [:read, :raw], fn f ->
      f
      |> IO.binread(@binread_arg)
      |> Base.encode64()
    end)
  end

  defp local_file?(file) do
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

  defp put_beam_metadata(
         %{capabilities: %{alwaysMatch: %{"moz:firefoxOptions": %{prefs: %{}}}}} = capabilities,
         opts
       ) do
    capabilities
    |> update_in(
      [:capabilities, :alwaysMatch, :"moz:firefoxOptions", :prefs, "general.useragent.override"],
      fn user_agent ->
        if user_agent do
          Metadata.append(user_agent, opts[:metadata])
        end
      end
    )
  end

  defp put_beam_metadata(capabilities, _opts), do: capabilities

  defp wdc_element_to_wallaby_element(parent, element) do
    %Wallaby.Element{
      id: element.id,
      session_url: parent.session_url,
      url: parent.session_url <> "/element/#{element.id}",
      parent: parent,
      driver: __MODULE__
    }
  end
end
