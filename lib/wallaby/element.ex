defmodule Wallaby.Element do
  @moduledoc """
  Defines an Element Struct
  """

  alias Wallaby.Phantom.Driver

  defstruct [:url, :session_url, :parent, :id, screenshots: []]

  @type url :: String.t
  @type query :: String.t
  @type locator :: Session.t | t
  @type t :: %__MODULE__{
    session_url: url,
    url: url,
    id: String.t,
    screenshots: list,
  }

  def clear(element) do
    case Driver.clear(element) do
      {:ok, _} ->
	element
      {:error, _} ->
	raise Wallaby.StaleReferenceException
    end
  end

  def fill_in(element, with: value) when is_number(value) do
    fill_in(element, with: to_string(value))
  end
  def fill_in(element, with: value) when is_binary(value) do
    element
    |> clear
    |> set_value(value)
  end

  def click(element) do
    case Driver.click(element) do
      {:ok, _} ->
	element
      {:error, _} ->
	raise Wallaby.StaleReferenceException
    end
  end

  def text(element) do
    case Driver.text(element) do
      {:ok, text} ->
        text
      {:error, :stale_reference_error} ->
        raise Wallaby.StaleReferenceException
    end
  end

  def attr(element, name) do
    case Driver.attribute(element, name) do
      {:ok, attribute} ->
	attribute
      {:error, _} ->
	raise Wallaby.StaleReferenceException
    end
  end

  def selected?(element) do
    case Driver.selected(element) do
      {:ok, value} ->
        value
      {:error, _} ->
        false
    end
  end

  def visible?(element) do
    case Driver.displayed(element) do
      {:ok, value} ->
	value
      {:error, _} ->
	false
    end
  end

  def set_value(element, value) do
    case Driver.set_value(element, value) do
      {:ok, _} ->
	element
      {:error, :stale_reference_error} ->
	raise Wallaby.StaleReferenceException
    end
  end
end

