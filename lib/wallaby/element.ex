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
    element
    |> driver.clear()
    |> handle_action_result(element)
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
      {:error, :obscured} ->
        if retry_count > 4 do
          raise Wallaby.ExpectationNotMetError, """
          The element you tried to click is obscured by another element.
          """
        else
          click(element, retry_count + 1)
        end

      result ->
        handle_action_result(result, element)
    end
  end

  @doc """
  Hovers on the element.
  """
  @spec hover(t) :: t

  def hover(%__MODULE__{driver: driver} = element) do
    element
    |> driver.hover()
    |> handle_action_result(element)
  end

  @doc """
  Touches and holds the element on its top-left corner plus an optional offset.
  """
  @spec touch_down(t, integer, integer) :: t

  def touch_down(%__MODULE__{driver: driver} = element, x_offset \\ 0, y_offset \\ 0) do
    driver.touch_down(element, element, x_offset, y_offset)
    |> handle_action_result(element)
  end

  @doc """
  Taps the element.
  """
  @spec tap(t) :: t

  def tap(%__MODULE__{driver: driver} = element) do
    element
    |> driver.tap()
    |> handle_action_result(element)
  end

  @doc """
  Scroll on the screen from the given element by the given offset using touch events.
  """
  @spec touch_scroll(t, integer, integer) :: t

  def touch_scroll(%__MODULE__{driver: driver} = element, x_offset, y_offset) do
    element
    |> driver.touch_scroll(x_offset, y_offset)
    |> handle_action_result(element)
  end

  @doc """
  Gets the element's text value.

  If the element is not visible, the return value will be `""`.
  """
  @spec text(t) :: String.t()

  def text(%__MODULE__{driver: driver} = element) do
    element
    |> driver.text()
    |> handle_value_result()
  end

  @doc """
  Gets the value of the element's attribute.
  """
  @spec attr(t, attr()) :: String.t() | nil

  def attr(%__MODULE__{driver: driver} = element, name) do
    element
    |> driver.attribute(name)
    |> handle_value_result()
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
    element
    |> driver.selected()
    |> handle_boolean_result()
  end

  @doc """
  Returns a boolean based on whether or not the element is visible.
  """
  @spec visible?(t) :: boolean()

  def visible?(%__MODULE__{driver: driver} = element) do
    element
    |> driver.displayed()
    |> handle_boolean_result()
  end

  @doc """
  Sets the value of the element.
  """
  @spec set_value(t, value()) :: t

  def set_value(%__MODULE__{driver: driver} = element, value) do
    element
    |> driver.set_value(value)
    |> handle_action_result(element)
  end

  @doc """
  Sends keys to the element.
  """
  @spec send_keys(t, keys_to_send) :: t

  def send_keys(element, text) when is_binary(text) do
    send_keys(element, [text])
  end

  def send_keys(%__MODULE__{driver: driver} = element, keys) when is_list(keys) do
    element
    |> driver.send_keys(keys)
    |> handle_action_result(element)
  end

  @doc """
  Returns the Element's value.
  """
  @spec value(t) :: String.t()

  def value(element) do
    attr(element, "value")
  end

  @doc """
  Returns a tuple `{width, height}` with the size of the given element.
  """
  @spec size(t) :: {non_neg_integer, non_neg_integer}

  def size(%__MODULE__{driver: driver} = element) do
    element
    |> driver.element_size()
    |> handle_value_result()
  end

  @doc """
  Returns a tuple `{x, y}` with the coordinates of the left-top corner of given element.
  """
  @spec location(t) :: {non_neg_integer, non_neg_integer}

  def location(%__MODULE__{driver: driver} = element) do
    element
    |> driver.element_location()
    |> handle_value_result()
  end

  defp handle_action_result(result, element) do
    case result do
      {:ok, _} -> element
      {:error, error} -> raise_error(error)
    end
  end

  defp handle_value_result(result) do
    case result do
      {:ok, value} -> value
      {:error, error} -> raise_error(error)
    end
  end

  defp handle_boolean_result(result) do
    case result do
      {:ok, true} -> true
      {:ok, false} -> false
      {:error, error} -> raise_error(error)
    end
  end

  defp raise_error(:stale_reference), do: raise(StaleReferenceError)
  defp raise_error(error), do: raise(RuntimeError, inspect(error))
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
