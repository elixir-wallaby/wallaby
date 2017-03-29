defmodule Wallaby.Browser do
  @moduledoc """
  The Browser module is the entrypoint for interacting with a real browser.

  By default, action only work with elements that are visible to a real user.

  ## Actions

  Actions are used to interact with form elements. All actions work with the
  query interface:

  ```html
  <label for="first_name">
    First Name
  </label>
  <input id="user_first_name" type="text" name="first_name">
  ```

  ```
  fill_in(page, Query.text_field("First Name"), with: "Grace")
  fill_in(page, Query.text_field("first_name"), with: "Grace")
  fill_in(page, Query.text_field("user_first_name"), with: "Grace")
  ```

  These queries work with any of the available actions.

  ```
  fill_in(page, Query.text_field("First Name"), with: "Chris")
  clear(page, Query.text_field("user_email"))
  click(page, Query.radio_button("Radio Button 1"))
  click(page, Query.checkbox("Checkbox"))
  click(page, Query.checkbox("Checkbox"))
  click(page, Query.option("Option 1"))
  click(page, Query.button("Some Button"))
  attach_file(page, Query.file_field("Avatar"), path: "test/fixtures/avatar.jpg")
  ```

  Actions return their parent element so that they can be chained together:

  ```
  page
  |> find(Query.css(".signup-form"), fn(form) ->
    form
    |> fill_in(Query.text_field("Name"), with: "Grace Hopper")
    |> fill_in(Query.text_field("Email"), with: "grace@hopper.com")
    |> click(Query.button("Submit"))
  end)
  ```

  ## Scoping

  Finders provide scoping like so:

  ```
  session
  |> visit("/page.html")
  |> find(Query.css(".users"))
  |> find(Query.css(".user", count: 3))
  |> List.first
  |> find(Query.css(".user-name"))
  ```

  If a callback is passed to find then the scoping will only apply to the callback
  and the parent will be passed to the next action in the chain:

  ```
  page
  |> find(Query.css(".todo-form"), fn(form) ->
    form
    |> fill_in(Query.text_field("What needs doing?"), with: "Write Wallaby Documentation")
    |> click(Query.button("Save"))
  end)
  |> find(Query.css(".success-notification"), fn(notification) ->
    assert notification
    |> has_text?("Todo created successfully!")
  end)
  ```

  This allows you to create a test that is logically grouped together in a single pipeline.
  It also means that its easy to create re-usable helper functions without having to worry about
  chaining. You could re-write the above example like this:

  ```
  def create_todo(page, todo) do
    find(Query.css(".todo-form"), & fill_in_and_save_todo(&1, todo))
  end

  def fill_in_and_save_todo(form, todo) do
    form
    |> fill_in(Query.text_field("What needs doing?"), with: todo)
    |> click(Query.button("Save"))
  end

  def todo_was_created?(page) do
    find Query.css(page, ".success-notification"), fn(notification) ->
      assert notification
      |> has_text?("Todo created successfully!")
    end
  end

  assert page
  |> create_todo("Write Wallaby Documentation")
  |> todo_was_created?
  """

  alias Wallaby.Element
  alias Wallaby.Phantom.Driver
  alias Wallaby.Query
  alias Wallaby.Query.ErrorMessage
  alias Wallaby.Session

  @type t :: any()

  @opaque session :: Session.t
  @opaque element :: Element.t
  @opaque queryable :: Query.t
                     | Element.t

  @type parent :: element
                | session
  @type locator :: String.t
  @type opts :: Query.opts()

  @default_max_wait_time 3_000

  @doc """
  Attempts to synchronize with the browser. This is most often used to
  execute queries repeatedly until it either exceeds the time limit or
  returns a success.

  ## Note

  It is possible that this function never halts. Whenever we experience a stale
  reference error we retry the query without checking to see if we've run over
  our time. In practice we should eventually be able to query the dom in a stable
  state. However, if this error does continue to occur it will cause wallaby to
  loop forever (or until the test is killed by exunit).
  """
  @opaque sync_result :: {:ok, any()} | {:error, any()}
  @spec retry((() -> sync_result), timeout) :: sync_result()

  def retry(f, start_time \\ current_time()) do
    case f.() do
      {:ok, result} ->
        {:ok, result}
      {:error, :stale_reference} ->
        retry(f, start_time)
      {:error, e} ->
        if max_time_exceeded?(start_time) do
          {:error, e}
        else
          retry(f, start_time)
        end
    end
  end

  @doc """
  Fills in a "fillable" element with text. Input elements are looked up by id, label text,
  or name.
  """
  @spec fill_in(element, opts) :: element
  @spec fill_in(parent, Query.t, with: String.t) :: parent
  @spec fill_in(parent, locator, opts) :: parent

  def fill_in(parent, locator, [{:with, value} | _]=opts) when is_binary(locator) do
    IO.warn """
    fill_in/3 with string locators has been deprecated. Please use a query: fill_in(parent, Query.text_field("#{locator}"), with: "#{value}")
    """

    parent
    |> find(Query.fillable_field(locator, opts), &(Element.fill_in(&1, with: value)))
  end
  def fill_in(parent, query, with: value) do
    parent
    |> find(query, &(Element.fill_in(&1, with: value)))
  end
  def fill_in(%Element{}=element, with: value) do
    IO.warn "fill_in/2 has been deprecated. Please use Element.fill_in/2"

    Element.fill_in(element, with: value)
  end

  @doc """
  Chooses a radio button based on id, label text, or name.
  """
  @spec choose(Element.t) :: Element.t
  @spec choose(parent, Query.t) :: parent
  @spec choose(parent, locator, opts) :: parent

  def choose(parent, locator, opts) when is_binary(locator) do
    IO.warn """
    choose/3 has been deprecated. Please use: click(parent, Query.radio_button("#{locator}", #{inspect(opts)}))
    """

    parent
    |> find(Query.radio_button(locator, opts), &Element.click/1)
  end
  def choose(parent, locator) when is_binary(locator) do
    IO.warn """
    choose/2 has been deprecated. Please use: click(parent, Query.radio_button("#{locator}"))
    """

    parent
    |> find(Query.radio_button(locator, []), &Element.click/1)
  end
  def choose(parent, query) do
    IO.warn "choose/2 has been deprecated. Please use click/2"

    parent
    |> find(query, &Element.click/1)
  end
  def choose(%Element{}=element) do
    IO.warn "choose/1 has been deprecated. Please use Element.click/1"

    Element.click(element)
  end

  @doc """
  Checks a checkbox based on id, label text, or name.
  """
  @spec check(Element.t) :: Element.t
  @spec check(parent, Query.t) :: parent
  @spec check(parent, locator, opts) :: parent

  def check(%Element{}=element) do
    IO.warn "check/1 has been deprecated. Please use Element.click/1"

    cond do
      Element.selected?(element) -> element
      true -> Element.click(element)
    end
  end
  def check(parent, locator) when is_binary(locator) do
    IO.warn """
    check/2 has been deprecated. Please use: click(parent, Query.checkbox("#{locator}"))
    """

    parent
    |> find(Query.checkbox(locator, []), fn(element) ->
      if !Element.selected?(element) do
      	Element.click(element)
      end
    end)
  end
  def check(parent, query) do
    IO.warn "check/2 has been deprecated. Please use click/2"

    parent
    |> find(query, fn (element) ->
      if !Element.selected?(element) do
      	Element.click(element)
      end
    end)
  end
  def check(parent, locator, opts) when is_binary(locator) do
    IO.warn """
    check/2 has been deprecated. Please use: click(parent, Query.checkbox("#{locator}", #{inspect(opts)}))
    """

    parent
    |> find(Query.checkbox(locator, opts), fn(element) ->
      if ! Element.selected?(element) do
      	Element.click(element)
      end
    end)
  end

  @doc """
  Unchecks a checkbox based on id, label text, or name.
  """
  @spec uncheck(Element.t) :: Element.t
  @spec uncheck(parent, Query.t) :: parent
  @spec uncheck(parent, locator, opts) :: parent

  def uncheck(parent, locator, opts) when is_binary(locator) do
    IO.warn """
    uncheck/2 has been deprecated. Please use: click(parent, Query.checkbox("#{locator}", #{inspect(opts)}))
    """

    parent
    |> find(Query.checkbox(locator, opts), &Element.click/1)
  end
  def uncheck(parent, locator) when is_binary(locator) do
    IO.warn """
    check/2 has been deprecated. Please use: click(parent, Query.checkbox("#{locator}"))
    """
    parent
    |> find(Query.checkbox(locator, []), fn (element) ->
      if Element.selected?(element) do
      	Element.click(element)
      end
    end)
  end
  def uncheck(parent, query) do
    IO.warn "uncheck/2 has been deprecated. Please use click/2"

    parent
    |> find(query, fn(element) ->
      if Element.selected?(element) do
      	Element.click(element)
      end
    end)
  end
  def uncheck(%Element{}=element) do
    IO.warn "uncheck/1 has been deprecated. Please use Element.click/1"

    if Element.selected?(element) do
      Element.click(element)
    end
    element
  end

  @doc """
  Selects an option from a select box. The select box can be found by id, label
  text, or name. The option can be found by its text.
  """
  @spec select(Element.t) :: Element.t
  @spec select(parent, Query.t) :: parent
  @spec select(parent, Query.t, from: Query.t) :: parent
  @spec select(parent, locator, opts) :: parent

  def select(element) do
    IO.warn "select/1 has been deprecated. Please use Element.click/1"

    Element.click(element)
  end
  def select(parent, query) do
    IO.warn "select/2 has been deprecated. Please use click/2"

    parent
    |> find(query, &Element.click/1)
  end
  def select(parent, locator, [option: option_text]=opts) do
    IO.warn """
    select/3 has been deprecated. Please use:

    click(parent, Query.option("#{option_text}"))
    """

    find(parent, Query.select(locator, opts), fn(select_field) ->
      find(select_field, Query.option(option_text, []), fn(option) ->
        Element.click(option)
      end)
    end)
  end

  @doc """
  Clicks the matching link. Links can be found based on id, name, or link text.
  """
  @spec click_link(parent, Query.t) :: parent
  @spec click_link(parent, locator, opts) :: parent

  def click_link(parent, locator, opts) when is_binary(locator) do
    IO.warn """
    click_link/3 has been deprecated. Please use: click(parent, Query.link("#{locator}", #{inspect(opts)}))
    """

    parent
    |> click(Query.link(locator, opts))
  end
  def click_link(parent, locator) when is_binary(locator) do
    IO.warn """
    click_link/2 has been deprecated. Please use: click(parent, Query.link("#{locator}"))
    """

    parent
    |> click(Query.link(locator, []))
  end
  def click_link(parent, query) do
    IO.warn "click_link/2 has been deprecated. Please use click/2"

    click(parent, query)
  end

  @doc """
  Clicks the matching button. Buttons can be found based on id, name, or button text.
  """
  @spec click_button(parent, Query.t) :: parent
  @spec click_button(parent, locator, opts) :: parent

  def click_button(parent, locator, opts) when is_binary(locator) do
    IO.warn """
    click_button/3 has been deprecated. Please use: click(parent, Query.button("#{locator}", #{inspect(opts)}))
    """

    parent
    |> click(Query.button(locator, opts))
  end
  def click_button(parent, locator) when is_binary(locator) do
    IO.warn """
    click_button/2 has been deprecated. Please use: click(parent, Query.button("#{locator}"))
    """

    parent
    |> click(Query.button(locator, []))
  end
  def click_button(parent, query) do
    IO.warn "click_button/2 has been deprecated. Please use click/2"

    click(parent, query)
  end

  # @doc """
  # Clears an input field. Input elements are looked up by id, label text, or name.
  # The element can also be passed in directly.
  # """
  @spec clear(parent, locator, opts) :: parent
  @spec clear(parent, Query.t) :: parent
  @spec clear(Element.t) :: Element.t

  def clear(parent, locator, opts) when is_binary(locator) do
    IO.warn """
    clear/3 has been deprecated. Please use: clear(parent, Query.css("#{locator}", #{inspect(opts)}))
    """

    clear(parent, Query.fillable_field(locator, opts))
  end
  def clear(parent, query) do
    parent
    |> find(query, &Element.clear/1)
  end
  def clear(element) do
    IO.warn "clear/1 has been deprecated. Please use Element.clear/1"

    Element.clear(element)
  end

  @doc """
  Attaches a file to a file input. Input elements are looked up by id, label text,
  or name.
  """
  @spec attach_file(parent, locator, opts) :: parent
  @spec attach_file(parent, queryable, path: String.t) :: parent

  def attach_file(parent, locator, [{:path, value} | _]=opts) when is_binary(locator) do
    IO.warn """
    attach_file/3 with string locators has been deprecated. Please use:

    attach_file(parent, Query.file_field("#{locator}"))
    """

    parent
    |> fill_in(Query.file_field(locator, opts), with: :filename.absname(value))
  end
  def attach_file(parent, query, path: path) do
    parent
    |> fill_in(query, with: :filename.absname(path))
  end

  @doc """
  Takes a screenshot of the current window.
  Screenshots are saved to a "screenshots" directory in the same directory the
  tests are run in.
  """
  @spec take_screenshot(parent) :: parent

  def take_screenshot(screenshotable) do
    image_data =
      screenshotable
      |> Driver.take_screenshot

    path = path_for_screenshot()
    File.write! path, image_data

    Map.update(screenshotable, :screenshots, [], &(&1 ++ [path]))
  end

  @doc """
  Gets the size of the session's window.
  """
  @spec window_size(parent) :: %{String.t => pos_integer, String.t => pos_integer}

  def window_size(session) do
    {:ok, size} = Driver.get_window_size(session)
    size
  end

  @doc """
  Sets the size of the sessions window.
  """
  @spec resize_window(parent, pos_integer, pos_integer) :: parent

  def resize_window(session, width, height) do
    {:ok, _} = Driver.set_window_size(session, width, height)
    session
  end

  def set_window_size(parent, x, y) do
    IO.warn "set_window_size/3 has been deprecated. Please use resize_window/3"

    resize_window(parent, x, y)
  end

  @doc """
  Gets the current url of the session
  """
  @spec current_url(parent) :: String.t

  def current_url(parent) do
    Driver.current_url!(parent)
  end

  def get_current_url(parent) do
    IO.warn "get_current_url/1 has been deprecated. Please use current_url/1"

    current_url(parent)
  end

  @doc """
  Gets the current path of the session
  """
  @spec current_path(parent) :: String.t

  def current_path(parent) do
    Driver.current_path!(parent)
  end

  @doc """
  Gets the title for the current page
  """
  @spec page_title(parent) :: String.t

  def page_title(session) do
    {:ok, title} = Driver.page_title(session)
    title
  end

  @doc """
  Executes javascript synchoronously, taking as arguments the script to execute,
  and optionally a list of arguments available in the script via `arguments`
  """
  @spec execute_script(parent, String.t, list) :: parent

  def execute_script(session, script, arguments \\ []) do
    {:ok, value} = Driver.execute_script(session, script, arguments)
    value
  end

  @doc """
  Sends a list of key strokes to active element. If strings are included
  then they are sent as individual keys. Special keys should be provided as a
  list of atoms, which are automatically converted into the corresponding key
  codes.

  For a list of available key codes see `Wallaby.Helpers.KeyCodes`.

  ## Example

      iex> Wallaby.Session.send_keys(session, ["Example Text", :enter])
      iex> Wallaby.Session.send_keys(session, [:enter])
      iex> Wallaby.Session.send_keys(session, [:shift, :enter])
  """
  @spec send_keys(parent, Query.t, list(atom) | String.t) :: parent
  @spec send_keys(parent, list(atom) | String.t) :: parent

  def send_keys(parent, query, list) do
    find(parent, query, fn(element) ->
      element
      |> Element.send_keys(list)
    end)
  end
  def send_keys(%Element{}=element, keys) do
    Element.send_keys(element, keys)
  end

  def send_keys(parent, keys) when is_binary(keys) do
    send_keys(parent, [keys])
  end
  def send_keys(parent, keys) when is_list(keys) do
    {:ok, _} = Driver.send_keys(parent, keys)
    parent
  end

  def send_text(parent, query, keys) do
    IO.warn "send_text/3 has been deprecated. Please use send_keys/3"
    send_keys(parent, query, keys)
  end

  def send_text(parent, keys) do
    IO.warn "send_text/2 has been deprecated. Please use send_keys/2"
    send_keys(parent, keys)
  end


  @doc """
  Retrieves the source of the current page.
  """
  @spec page_source(parent) :: String.t

  def page_source(session) do
    {:ok, source} = Driver.page_source(session)
    source
  end

  @doc """
  Sets the value of an element.
  """
  @spec set_value(element, any()) :: element

  def set_value(element, value) do
    IO.warn "set_value/2 has been deprecated. Please use Element.set_value/2"

    Element.set_value(element, value)
  end

  @doc """
  Clicks a element.
  """
  @spec click(parent, Query.t) :: parent
  @spec click(Element.t) :: Element.t

  def click(parent, locator) when is_binary(locator) do
    IO.warn """
    click/2 with string locator has been deprecated. Please use:

    click(parent, Query.button("#{locator}"))
    """

    parent
    |> find(Query.button(locator), &Element.click/1)
  end
  def click(parent, query) do
    parent
    |> find(query, &Element.click/1)
  end
  def click(element) do
    IO.warn "click/1 has been deprecated. Please use Element.click/1"

    Element.click(element)
  end

  def click_on(parent, query) do
    IO.warn """
    click_on/2 has been deprecated. Please use Browser.click/2.
    """

    click(parent, query)
  end

  @doc """
  Gets the Element's text value.
  """
  @spec text(parent) :: String.t
  @spec text(parent, Query.t) :: String.t

  def text(parent, query) do
    parent
    |> find(query)
    |> Element.text
  end
  def text(%Session{}=session) do
    session
    |> find(Query.css("body"))
    |> Element.text()
  end
  def text(%Element{}=element) do
    IO.warn "text/1 has been deprecated. Please use Element.text/1"

    Element.text(element)
  end

  @doc """
  Gets the value of the elements attribute.
  """
  @spec attr(parent, Query.t, String.t) :: String.t | nil
  @spec attr(Element.t, String.t) :: String.t | nil

  def attr(element, name) do
    IO.warn "attr/2 has been deprecated. Please use Element.attr/2"
    Element.attr(element, name)
  end
  def attr(parent, query, name) do
    parent
    |> find(query)
    |> Element.attr(name)
  end

  @doc """
  Checks if the element has been selected.
  """
  @spec checked?(parent, Query.t) :: boolean()
  @spec checked?(Element.t) :: boolean()

  def checked?(parent, query) do
    IO.warn "checked?/2 has been deprecated. Please use selected?/2"
    selected?(parent, query)
  end
  def checked?(%Element{}=element) do
    IO.warn "checked?/1 has been deprecated. Please use Element.selected?/1"
    Element.selected?(element)
  end

  @doc """
  Checks if the element has been selected. Alias for checked?(element)
  """
  @spec selected?(parent, Query.t) :: boolean()
  @spec selected?(Element.t) :: boolean()

  def selected?(parent, query) do
    parent
    |> find(query)
    |> Element.selected?
  end
  def selected?(%Element{}=element) do
    IO.warn "selected?/1 has been deprecated. Please use Element.selected?/1"

    Element.selected?(element)
  end

  @doc """
  Checks if the element is visible on the page
  """
  @spec visible?(parent, Query.t) :: boolean()
  @spec visible?(Element.t) :: boolean()

  def visible?(%Element{}=element) do
    IO.warn "visible?/1 has been deprecated. Please use Element.visible?/1"

    Element.visible?(element)
  end
  def visible?(parent, query) do
    parent
    |> has?(query)
  end

  @doc """
  Finds a specific DOM element on the page based on a css selector. Blocks until
  it either finds the element or until the max time is reached. By default only
  1 element is expected to match the query. If more elements are present then a
  count can be specified. Use `:any` to allow any number of elements to be present.
  By default only elements that are visible on the page are returned.

  Selections can be scoped by providing a Element as the locator for the query.

  By default finders only work with elements that would be visible to a real
  user.
  """
  @spec find(parent, Query.t, ((Element.t) -> any())) :: parent
  @spec find(parent, Query.t) :: Element.t | [Element.t]
  @spec find(parent, locator) :: Element.t | [Element.t]

  def find(parent, css, opts) when is_binary(css) and is_list(opts) do
    IO.warn """
    find/3 with string locators has beeen deprecated. Please use: find(parent, Query.css("#{css}", #{inspect(opts)}))
    """

    find(parent, Query.css(css, opts))
  end
  def find(parent, %Query{}=query, callback) when is_function(callback) do
    results = find(parent, query)
    callback.(results)
    parent
  end
  def find(parent, {:xpath, path}) when is_binary(path) do
    IO.warn """
    find/3 with {:xpath, locator} has beeen deprecated. Please use: find(parent, Query.xpath("#{path}"))
    """

    find(parent, Query.xpath(path))
  end
  def find(parent, css) when is_binary(css) do
    IO.warn """
    find/3 with string locators has beeen deprecated. Please use: find(parent, Query.css("#{css}"))
    """

    find(parent, Query.css(css))
  end
  def find(parent, %Query{}=query) do
    case execute_query(parent, query) do
      {:ok, query} ->
        query
        |> Query.result

      {:error, {:not_found, result}} ->
        query = %Query{query | result: result}

        if Wallaby.screenshot_on_failure? do
          take_screenshot(parent)
        end

        case validate_html(parent, query) do
          {:ok, _} ->
            raise Wallaby.QueryError, ErrorMessage.message(query, :not_found)
          {:error, html_error} ->
            raise Wallaby.QueryError, ErrorMessage.message(query, html_error)
        end

      {:error, e} ->
        if Wallaby.screenshot_on_failure? do
          take_screenshot(parent)
        end

        raise Wallaby.QueryError, ErrorMessage.message(query, e)
    end
  end

  @doc """
  Finds all of the DOM elements that match the css selector. If no elements are
  found then an empty list is immediately returned.
  """
  @spec all(parent, locator, opts) :: [Element.t]
  @spec all(parent, locator) :: [Element.t]
  @spec all(parent, Query.t) :: [Element.t]

  def all(parent, locator, opts) when is_binary(locator) do
    IO.warn """
    all/3 with string locators has been deprecated. Please use: all(parent, Query.css("#{locator}", #{inspect(opts)}))
    """

    find(parent, Query.css(locator, Keyword.merge(opts, [count: nil, minimum: 0])))
  end
  def all(parent, css) when is_binary(css) do
    IO.warn """
    all/2 with string locators has been deprecated. Please use: all(parent, Query.css("#{css}"))
    """

    find(parent, Query.css(css, minimum: 0))
  end
  def all(parent, %Query{}=query) do
    find(
      parent,
      %Query{query | conditions: Keyword.merge(query.conditions, [count: nil, minimum: 0])})
  end

  @doc """
  Validates that the query returns a result. This can be used to define other
  types of matchers.
  """
  @spec has?(parent, Query.t) :: boolean()

  def has?(parent, query) do
    case execute_query(parent, query) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc """
  Matches the Element's value with the provided value.
  """
  @spec has_value?(parent, Query.t, any()) :: boolean()
  @spec has_value?(Element.t, any()) :: boolean()

  def has_value?(parent, query, value) do
    parent
    |> find(query)
    |> has_value?(value)
  end
  def has_value?(%Element{}=element, value) do
    Element.value(element) == value
  end

  @doc """
  Matches the Element's content with the provided text
  """
  @spec has_text?(Element.t, String.t) :: boolean()
  @spec has_text?(parent, Query.t, String.t) :: boolean()

  def has_text?(parent, query, text) do
    parent
    |> find(query)
    |> has_text?(text)
  end
  def has_text?(%Session{}=session, text) when is_binary(text) do
    session
    |> find(Query.css("body"))
    |> has_text?(text)
  end
  def has_text?(parent, text) when is_binary(text) do
    result = retry fn ->
      cond do
        Element.text(parent) =~ text ->
          {:ok, true}
        true ->
          {:error, false}
      end
    end

    case result do
      {:ok, true} ->
        true
      {:error, false} ->
        false
    end
  end

  @doc """
  Matches the Element's content with the provided text and raises if not found
  """
  @spec assert_text(Element.t, String.t) :: boolean()
  @spec assert_text(parent, Query.t, String.t) :: boolean()

  def assert_text(parent, query, text) when is_binary(text) do
    parent
    |> find(query)
    |> assert_text(text)
  end
  def assert_text(parent, text) when is_binary(text) do
    cond do
      has_text?(parent, text) -> true
      true -> raise Wallaby.ExpectationNotMet, "Text '#{text}' was not found."
    end
  end

  @doc """
  Checks if `query` is present within `parent` and raises if not found.

  Returns the given `parent` if the assertion is correct so that it is easily
  pipeable.

  ## Examples

      session
      |> visit("/")
      |> assert_has(Query.css(".login-button"))
  """
  @spec assert_has(parent, Query.t) :: parent

  defmacro assert_has(parent, query) do
    quote do
      parent = unquote(parent)
      query  = unquote(query)

      case execute_query(parent, query) do
        {:ok, _query_result} ->
          parent
        {:error, _not_found} ->
          raise Wallaby.ExpectationNotMet,
                Query.ErrorMessage.message(query, :not_found)

      end
    end
  end

  @doc """
  Checks if `query` is not present within `parent` and raises if it is found.

  Returns the given `parent` if the query is not found so that it is easily
  pipeable.

  ## Examples

      session
      |> visit("/")
      |> refute_has(Query.css(".secret-admin-content"))
  """
  @spec refute_has(parent, Query.t) :: parent

  defmacro refute_has(parent, query) do
    quote do
      parent = unquote(parent)
      query  = unquote(query)

      case execute_query(parent, query) do
        {:error, _not_found} ->
          parent
        {:ok, query} ->
          raise Wallaby.ExpectationNotMet,
                Query.ErrorMessage.message(query, :found)
      end
    end
  end

  @doc """
  Searches for CSS on the page.
  """
  @spec has_css?(parent, Query.t, String.t) :: boolean()
  @spec has_css?(parent, locator) :: boolean()

  def has_css?(parent, query, css) when is_binary(css) do
    parent
    |> find(query)
    |> has?(Query.css(css, count: :any))
  end
  def has_css?(parent, css) when is_binary(css) do
    parent
    |> find(Wallaby.Query.css(css, count: :any))
    |> Enum.any?
  end

  @doc """
  Searches for css that should not be on the page
  """
  @spec has_no_css?(parent, Query.t, String.t) :: boolean()
  @spec has_no_css?(parent, locator) :: boolean()

  def has_no_css?(parent, query, css) when is_binary(css) do
    parent
    |> find(query)
    |> has?(Query.css(css, count: 0))
  end
  def has_no_css?(parent, css) when is_binary(css) do
    parent
    |> has?(Query.css(css, count: 0))
  end

  @doc """
  Changes the current page to the provided route.
  Relative paths are appended to the provided base_url.
  Absolute paths do not use the base_url.
  """
  @spec visit(parent, String.t) :: Session.t

  def visit(session, path) do
    uri = URI.parse(path)

    cond do
      uri.host == nil && String.length(base_url()) == 0 ->
        raise Wallaby.NoBaseUrl, path
      uri.host ->
        Driver.visit(session, path)
      true ->
        Driver.visit(session, request_url(path))
    end

    session
  end

  def cookies(%Session{}=session) do
    {:ok, cookies_list} = Driver.cookies(session)

    cookies_list
  end

  def set_cookie(%Session{}=session, key, value) do
    if blank_page?(session) do
      raise Wallaby.CookieException
    end

    case Driver.set_cookies(session, key, value) do
      {:ok, _list} ->
      	session
      {:error, :invalid_cookie_domain} ->
      	raise Wallaby.CookieException
    end
  end

  defp blank_page?(session) do
    current_url(session) == "about:blank"
  end

  defp validate_html(parent, %{html_validation: :button_type}=query) do
    buttons = all(parent, Query.css("button", [text: query.selector]))

    cond do
      Enum.any?(buttons) ->
        {:error, :button_with_bad_type}
      true ->
        {:ok, query}
    end
  end
  defp validate_html(parent, %{html_validation: :bad_label}=query) do
    label_query = Query.css("label", text: query.selector)
    labels = all(parent, label_query)

    cond do
      Enum.any?(labels, &(missing_for?(&1))) ->
        {:error, :label_with_no_for}
      label=List.first(labels) ->
        {:error, {:label_does_not_find_field, Element.attr(label, "for")}}
      true ->
        {:ok, query}
    end
  end
  defp validate_html(_, query), do: {:ok, query}

  defp missing_for?(element) do
    Element.attr(element, "for") == nil
  end

  defp validate_visibility(query, elements) do
    visible = Query.visible?(query)

    {:ok, Enum.filter(elements, &(Element.visible?(&1) == visible))}
  end

  defp validate_count(query, elements) do
    cond do
      Query.matches_count?(query, Enum.count(elements)) ->
        {:ok, elements}
      true ->
        {:error, {:not_found, elements}}
    end
  end

  defp validate_text(query, elements) do
    text = Query.inner_text(query)

    if text do
      {:ok, Enum.filter(elements, &(matching_text?(&1, text)))}
    else
      {:ok, elements}
    end
  end

  defp matching_text?(element, text) do
    case Driver.text(element) do
      {:ok, element_text} ->
        element_text =~ ~r/#{Regex.escape(text)}/
      {:error, _} ->
        false
    end
  end

  def execute_query(parent, query) do
    retry fn ->
      try do
        with {:ok, query}  <- Query.validate(query),
             {method, selector} <- Query.compile(query),
             {:ok, elements} <- Driver.find_elements(parent, {method, selector}),
             {:ok, elements} <- validate_visibility(query, elements),
             {:ok, elements} <- validate_text(query, elements),
             {:ok, elements} <- validate_count(query, elements),
         do: {:ok, %Query{query | result: elements}}
      rescue
        Wallaby.StaleReferenceException ->
          {:error, :stale_reference}
      end
    end
  end

  defp max_time_exceeded?(start_time) do
    current_time() - start_time > max_wait_time()
  end

  defp current_time do
    :erlang.monotonic_time(:milli_seconds)
  end

  defp max_wait_time do
    Application.get_env(:wallaby, :max_wait_time, @default_max_wait_time)
  end

  defp request_url(path) do
    base_url() <> path
  end

  defp base_url do
    Application.get_env(:wallaby, :base_url) || ""
  end

  defp path_for_screenshot do
    File.mkdir_p!(screenshot_dir())
    "#{screenshot_dir()}/#{:erlang.system_time}.png"
  end

  defp screenshot_dir do
    Application.get_env(:wallaby, :screenshot_dir) || "#{File.cwd!()}/screenshots"
  end
end
