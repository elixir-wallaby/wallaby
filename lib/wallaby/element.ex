defmodule Wallaby.Element do
  @moduledoc """
  Defines an Element Struct and interactions with Elements.

  Typically these functions are used in conjunction with a `find`:

  ```
  page
  |> find(Query.css(".some-element"), fn(element) -> Element.click(element) end)
  ```

  These functions can be used to create new actions specific to your application:

  ```
  def create_todo(todo_field, todo_text) do
    todo_field
    |> Element.click()
    |> Element.fill_in(with: todo_text)
    |> Element.send_keys([:enter])
  end
  ```

  ## Retrying

  Unlike `Browser` the actions in `Element` do not retry if the element becomes stale. Instead an exception will be raised.
  """

  alias Wallaby.InvalidSelectorError
  alias Wallaby.StaleReferenceError

  defstruct [:url, :session_url, :parent, :id, :driver, screenshots: []]

  @type value ::
          String.t()
          | number()
          | :selected
          | :unselected
  @type attr :: String.t()
  @type keys_to_send :: String.t() | list(atom | String.t())
  @type t :: %__MODULE__{
          session_url: String.t(),
          url: String.t(),
          id: String.t(),
          screenshots: list,
          driver: module
        }

  @doc """
  Clears any value set in the element.
  """
  @spec clear(t) :: t

  def clear(%__MODULE__{driver: driver} = element) do
    case driver.clear(element) do
      {:ok, _} ->
        element

      {:error, :stale_reference} ->
        raise StaleReferenceError

      {:error, :invalid_selector} ->
        raise InvalidSelectorError
    end
  end

  @doc """
  Fills in the element with the specified value.
  """
  @spec fill_in(t, with: String.t() | number()) :: t

  def fill_in(element, with: value) when is_number(value) do
    fill_in(element, with: to_string(value))
  end

  def fill_in(element, with: value) when is_binary(value) do
    element
    |> clear
    |> set_value(value)
  end

  @doc """
  Clicks the element.
  """
  @spec click(t) :: t

  def click(%__MODULE__{driver: driver} = element, retry_count \\ 0) do
    case driver.click(element) do
      {:ok, _} ->
        element

      {:error, :stale_reference} ->
        raise StaleReferenceError

      {:error, :obscured} ->
        if retry_count > 4 do
          raise Wallaby.ExpectationNotMetError, """
          The element you tried to click is obscured by another element.
          """
        else
          click(element, retry_count + 1)
        end
    end
  end

  @doc """
  Hovers on the element.
  """
  @spec hover(t) :: t

  def hover(%__MODULE__{driver: driver} = element) do
    case driver.hover(element) do
      {:ok, _} ->
        element
    end
  end

  @doc """
  Touches and holds the element on its top-left corner plus an optional offset.
  """
  @spec touch_down(t, integer, integer) :: t

  def touch_down(%__MODULE__{driver: driver} = element, x_offset \\ 0, y_offset \\ 0) do
    case driver.touch_down(element, element, x_offset, y_offset) do
      {:ok, _} ->
        element
    end
  end

  @doc """
  Taps the element.
  """
  @spec tap(t) :: t

  def tap(%__MODULE__{driver: driver} = element) do
    case driver.tap(element) do
      {:ok, _} ->
        element
    end
  end

  @doc """
  Scroll on the screen from the given element by the given offset using touch events.
  """
  @spec touch_scroll(t, integer, integer) :: t

  def touch_scroll(%__MODULE__{driver: driver} = element, x_offset, y_offset) do
    case driver.touch_scroll(element, x_offset, y_offset) do
      {:ok, _} ->
        element
    end
  end

  @doc """
  Gets the element's text value.

  If the element is not visible, the return value will be `""`.
  """
  @spec text(t) :: String.t()

  def text(%__MODULE__{driver: driver} = element) do
    case driver.text(element) do
      {:ok, text} ->
        text

      {:error, :stale_reference} ->
        raise StaleReferenceError
    end
  end

  @doc """
  Gets the value of the element's attribute.
  """
  @spec attr(t, attr()) :: String.t() | nil

  def attr(%__MODULE__{driver: driver} = element, name) do
    case driver.attribute(element, name) do
      {:ok, attribute} ->
        attribute

      {:error, :stale_reference} ->
        raise StaleReferenceError
    end
  end

  @doc """
  Returns a boolean based on whether or not the element is selected.

  ## Note
  This only really makes sense for options, checkboxes, and radio buttons.
  Everything else will simply return false because they have no notion of
  "selected".
  """
  @spec selected?(t) :: boolean()

  def selected?(%__MODULE__{driver: driver} = element) do
    case driver.selected(element) do
      {:ok, value} ->
        value

      {:error, _} ->
        false
    end
  end

  @doc """
  Returns a boolean based on whether or not the element is visible.
  """
  @spec visible?(t) :: boolean()

  def visible?(%__MODULE__{driver: driver} = element) do
    case driver.displayed(element) do
      {:ok, value} ->
        value

      {:error, _} ->
        false
    end
  end

  @doc """
  Sets the value of the element.
  """
  @spec set_value(t, value()) :: t

  def set_value(%__MODULE__{driver: driver} = element, value) do
    case driver.set_value(element, value) do
      {:ok, _} ->
        element

      {:error, :stale_reference} ->
        raise StaleReferenceError

      error ->
        error
    end
  end

  @doc """
  Sends keys to the element.
  """
  @spec send_keys(t, keys_to_send) :: t

  def send_keys(element, text) when is_binary(text) do
    send_keys(element, [text])
  end

  def send_keys(%__MODULE__{driver: driver} = element, keys) when is_list(keys) do
    case driver.send_keys(element, keys) do
      {:ok, _} ->
        element

      {:error, :stale_reference} ->
        raise StaleReferenceError

      error ->
        error
    end
  end

  @doc """
  Matches the Element's value with the provided value.
  """
  @spec value(t) :: String.t()

  def value(element) do
    attr(element, "value")
  end

  @doc """
  Returns a tuple `{width, height}` with the size of the given element.
  """
  @spec size(t) :: t

  def size(%__MODULE__{driver: driver} = element) do
    case driver.element_size(element) do
      {:ok, value} ->
        value
    end
  end

  @doc """
  Returns a tuple `{x, y}` with the coordinates of the left-top corner of given element.
  """
  @spec location(t) :: t

  def location(%__MODULE__{driver: driver} = element) do
    case driver.element_location(element) do
      {:ok, value} ->
        value
    end
  end
end

defimpl Inspect, for: Wallaby.Element do
  import Inspect.Algebra

  def inspect(element, opts) do
    additional_output =
      try do
        outer_html = Wallaby.Element.attr(element, "outerHTML")

        [
          "\n\n",
          IO.ANSI.cyan() <> "outerHTML:\n\n" <> IO.ANSI.reset(),
          IO.ANSI.yellow() <> outer_html <> IO.ANSI.reset()
        ]
      rescue
        _ ->
          []
      end

    concat([Inspect.Any.inspect(element, opts)] ++ additional_output)
  end
end
