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
  @type t :: %__MODULE__{
    session_url: String.t,
    url: String.t,
    id: String.t,
    screenshots: list,
  }

  @doc """
  Clears any value set in the element.
  """
  @spec clear(Element.t) :: Element.t

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
  @spec fill_in(Element.t, with: String.t | number()) :: Element.t

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
  @spec click(Element.t) :: Element.t

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
  @spec text(Element.t) :: String.t

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
  @spec attr(Element.t, attr()) :: String.t | nil

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
  @spec selected?(Element.t) :: boolean()

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
  @spec visible?(Element.t) :: boolean()

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
  @spec set_value(Element.t, value()) :: Element.t

  def set_value(element, value) do
    case Driver.set_value(element, value) do
      {:ok, _} ->
	element
      {:error, :stale_reference_error} ->
	raise Wallaby.StaleReferenceException
    end
  end
end
