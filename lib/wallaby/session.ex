defmodule Wallaby.Session do
  @moduledoc """
  Common functionality for interacting with Sessions.

  Sessions are used to represent a user navigating through and interacting with
  different pages.

  ## Fields

  * `id` - The session id generated from the webdriver
  * `base_url` - The base url for the application under test.
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
    |> click_on("Share")

    {:ok, user2} = Wallaby.start_session
    user2
    |> visit("/page.html")
    |> fill_in("Share Message", with: "Hello yourself")
    |> click_on("Share")

    assert user1 |> find(".messages") |> List.last |> text == "Hello yourself"
    assert user2 |> find(".messages") |> List.first |> text == "Hello there"
  end
  ```
  """

  @type t :: %__MODULE__{
    id: integer(),
    base_url: String.t,
    server: pid()
  }

  alias __MODULE__
  alias Wallaby.Driver
  alias Wallaby.Node
  alias Wallaby.XPath

  defstruct [:id, :base_url, :server]

  @doc """
  Changes the current page to the provided route.
  Routes are relative to any base url provided.
  """
  @spec visit(t, String.t) :: t

  def visit(session, path) do
    Driver.visit(session, request_url(path))
    session
  end

  @doc """
  Clicks the matching link. Links can be found based on id, name, or link text.
  """
  @spec click_link(t, String.t) :: t

  def click_link(session, link) do
    Node.find(session, {:xpath, XPath.link(link)})
    |> Node.click
    session
  end

  @doc """
  Takes a screenshot of the current window.
  Screenshots are saved to a "screenshots" directory in the same directory the
  tests are run in.
  """
  @spec take_screenshot(t) :: %{session: t, path: String.t}

  def take_screenshot(%Node{session: session}=node) do
    take_screenshot(session)
    node
  end

  def take_screenshot(%Session{}=session) do
    path = Driver.take_screenshot(session)
    %{session: session, path: path}
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
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  @spec execute_script(t, String.t, list) :: t

  def execute_script(session, script, arguments \\ []) do
    Driver.execute_script(session, script, arguments)
  end

  @doc """
  Sends a list of key strokes to active element
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

  defp request_url(url) do
    (Application.get_env(:wallaby, :base_url) || "") <> url
  end
end
