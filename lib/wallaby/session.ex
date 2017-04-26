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
  @message_field Query.text_field("Share Message")
  @share_button Query.button("Share")
  @message_list Query.css(".messages")

  test "That multiple sessions work" do
    {:ok, user1} = Wallaby.start_session
    user1
    |> visit("/page.html")
    |> fill_in(@message_field, with: "Hello there!")
    |> click(@share_button)

    {:ok, user2} = Wallaby.start_session
    user2
    |> visit("/page.html")
    |> fill_in(@message_field, with: "Hello yourself")
    |> click(@share_button)

    assert user1 |> find(@message_list) |> List.last |> text == "Hello yourself"
    assert user2 |> find(@message_list) |> List.first |> text == "Hello there"
  end
  ```
  """

  @type t :: %__MODULE__{
    id: String.t,
    session_url: String.t,
    url: String.t,
    server: pid(),
    screenshots: list,
    driver: module
  }

  defstruct [:id, :url, :session_url, :server, :driver, screenshots: []]

  def set_window_size(parent, x, y) do
    IO.warn "set_window_size/3 has been deprecated. Please use Browser.resize_window/3"

    Wallaby.Browser.resize_window(parent, x, y)
  end
end
