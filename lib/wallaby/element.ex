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

  alias Wallaby.Phantom.Driver

  defstruct [:url, :session_url, :parent, :id, screenshots: []]

  @opaque value :: String.t | number()

  @type attr :: String.t
  @type keys_to_send :: String.t | list(atom | String.t)
  @type t :: %__MODULE__{
    session_url: String.t,
    url: String.t,
    id: String.t,
    screenshots: list,
  }

  @doc """
  Clears any value set in the element.
  """
  @spec clear(t) :: t

  def clear(element) do
    case Driver.clear(element) do
      {:ok, _} ->
	element
      {:error, _} ->
	raise Wallaby.StaleReferenceException
    end
  end

  @doc """
  Fills in the element with the specified value.
  """
  @spec fill_in(t, with: String.t | number()) :: t

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

  def click(element) do
    case Driver.click(element) do
      {:ok, _} ->
      	element
      {:error, _} ->
      	raise Wallaby.StaleReferenceException
    end
  end

  @doc """
  Returns the text from the element.
  """
  @spec text(t) :: String.t

  def text(element) do
    case Driver.text(element) do
      {:ok, text} ->
        text
      {:error, :stale_reference_error} ->
        raise Wallaby.StaleReferenceException
    end
  end

  @doc """
  Gets the value of the element's attribute.
  """
  @spec attr(t, attr()) :: String.t | nil

  def attr(element, name) do
    case Driver.attribute(element, name) do
      {:ok, attribute} ->
	attribute
      {:error, _} ->
	raise Wallaby.StaleReferenceException
    end
  end

  @doc """
  Returns a boolean based on whether or not the element is selected.

  ## Note
  This only really makes sense for options, checkboxes, and radi buttons.
  Everything else will simply return false because they have no notion of
  "selected".
  """
  @spec selected?(t) :: boolean()

  def selected?(element) do
    case Driver.selected(element) do
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

  def visible?(element) do
    case Driver.displayed(element) do
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

  def set_value(element, value) do
    case Driver.set_value(element, value) do
      {:ok, _} ->
	element
      {:error, :stale_reference_error} ->
	raise Wallaby.StaleReferenceException
    end
  end

  @doc """
  Sends keys to the element.
  """
  @spec send_keys(t, keys_to_send) :: t

  def send_keys(element, text) when is_binary(text) do
    send_keys(element, [text])
  end
  def send_keys(element, keys) when is_list(keys) do
    case Driver.send_keys(element, keys) do
      {:ok, _} ->
	element
      {:error, :stale_reference_error} ->
	raise Wallaby.StaleReferenceException
    end
  end

  @doc """
  Matches the Element's value with the provided value.
  """
  @spec value(t) :: String.t

  def value(element) do
    attr(element, "value")
  end
end
