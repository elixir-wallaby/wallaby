defmodule Wallaby.Session do
  @moduledoc """
  Common functionality for interacting with Sessions.

  Sessions are used to represent a user navigating through and interacting with
  different pages.

  ## Fields

  * `id` - The session id generated from the webdriver
  * `session_url` - The base url for the application under test.
  * `server` - The specific webdriver server that the session is running in.

  ## Multiple sessions

  Each session runs in its own browser so that each test runs in isolation.
  Because of this isolation multiple sessions can be created for a test:

  ```
  test "That multiple sessions work" do
    {:ok, user1} = Wallaby.start_session
    user1
    |> visit("/page.html")
    |> fill_in("Share Message", with: "Hello there!")
    |> click_button("Share")

    {:ok, user2} = Wallaby.start_session
    user2
    |> visit("/page.html")
    |> fill_in("Share Message", with: "Hello yourself")
    |> click_button("Share")

    assert user1 |> find(".messages") |> List.last |> text == "Hello yourself"
    assert user2 |> find(".messages") |> List.first |> text == "Hello there"
  end
  ```
  """

  @type t :: %__MODULE__{
    id: integer(),
    session_url: String.t,
    url: String.t,
    server: pid(),
    screenshots: list
  }

  alias Wallaby.Driver
  alias Wallaby.Node

  defstruct [:id, :url, :session_url, :server, screenshots: []]

  @doc """
  Changes the current page to the provided route.
  Relative paths are appended to the provided base_url.
  Absolute paths do not use the base_url.
  """
  @spec visit(t, String.t) :: t

  def visit(session, path) do
    uri = URI.parse(path)

    cond do
      uri.host == nil && String.length(base_url) == 0 ->
        raise Wallaby.NoBaseUrl, path
      uri.host ->
        Driver.visit(session, path)
      true ->
        Driver.visit(session, request_url(path))
    end

    session
  end

  @doc """
  Takes a screenshot of the current window.
  Screenshots are saved to a "screenshots" directory in the same directory the
  tests are run in.
  """
  @spec take_screenshot(Node.t | t) :: Node.t | t

  def take_screenshot(screenshotable) do
    image_data =
      screenshotable
      |> Driver.take_screenshot

    path = path_for_screenshot
    File.write! path, image_data

    Map.update(screenshotable, :screenshots, [], &(&1 ++ [path]))
  end

  @doc """
  Sets the size of the sessions window.
  """
  @spec set_window_size(t, pos_integer, pos_integer) :: t

  def set_window_size(session, width, height) do
    Driver.set_window_size(session, width, height)
    session
  end

  @doc """
  Gets the size of the session's window.
  """
  @spec get_window_size(t) :: %{String.t => pos_integer, String.t => pos_integer}

  def get_window_size(session) do
    Driver.get_window_size(session)
  end

  @doc """
  Gets the current url of the session
  """
  @spec get_current_url(t) :: String.t

  def get_current_url(session) do
     Driver.current_url(session)
  end

  @doc """
  Gets the current path of the session
  """
  @spec get_current_path(t) :: String.t

  def get_current_path(session) do
     URI.parse(get_current_url(session)).path
  end

  @doc """
  Gets the title for the current page
  """
  @spec page_title(t) :: String.t

  def page_title(session) do
    Driver.page_title(session)
  end

  @doc """
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  @spec execute_script(t, String.t, list) :: t

  def execute_script(session, script, arguments \\ []) do
    Driver.execute_script(session, script, arguments)
  end

  @doc """
  Sends a list of key strokes to active element. Keys should be provided as a
  list of atoms, which are automatically converted into the corresponding key
  codes.

  For a list of available key codes see `Wallaby.Helpers.KeyCodes`.

  ## Example

      iex> Wallaby.Session.send_keys(session, [:enter])
      iex> Wallaby.Session.send_keys(session, [:shift, :enter])
  """
  @spec send_keys(t, list(atom)) :: t

  def send_keys(session, keys) when is_list(keys) do
    Driver.send_keys(session, keys)
    session
  end

  @doc """
  Sends text characters to the active element
  """
  @spec send_text(t, String.t) :: t

  def send_text(session, text) do
    Driver.send_text(session, text)
    session
  end

  defp request_url(path) do
    base_url <> path
  end

  defp base_url do
    Application.get_env(:wallaby, :base_url) || ""
  end

  defp path_for_screenshot do
    {hour, minutes, seconds} = :erlang.time()
    {year, month, day} = :erlang.date()

    File.mkdir_p!(screenshot_dir)
    "#{screenshot_dir}/#{year}-#{month}-#{day}-#{hour}-#{minutes}-#{seconds}.png"
  end

  defp screenshot_dir do
    Application.get_env(:wallaby, :screenshot_dir) || "#{File.cwd!()}/screenshots"
  end
end
