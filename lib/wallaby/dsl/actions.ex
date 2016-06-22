defmodule Wallaby.DSL.Actions do
  alias Wallaby.Node

  @type parent :: Wallaby.Node.t | Wallaby.Session.t
  @type locator :: {atom, String.t}

  @doc """
  Fills in a "fillable" node with text. Input nodes are looked up by id, label text,
  or name.
  """
  @spec fill_in(parent, locator, [with: String.t]) :: parent

  def fill_in(parent, locator, with: value) when is_binary(value) do
    parent
    |> Node.Query.fillable_field(locator)
    |> Node.fill_in(with: value)

    parent
  end

  @doc """
  Chooses a radio button based on id, label text, or name.
  """
  @spec choose(parent, locator) :: parent

  def choose(parent, locator) when is_binary(locator) do
    parent
    |> Node.Query.radio_button(locator)
    |> Node.click

    parent
  end

  @doc """
  Checks a checkbox based on id, label text, or name.
  """
  def check(parent, locator) do
    parent
    |> Node.Query.checkbox(locator)
    |> Node.check

    parent
  end

  @doc """
  Unchecks a checkbox based on id, label text, or name.
  """
  def uncheck(parent, locator) do
    parent
    |> Node.Query.checkbox(locator)
    |> Node.uncheck

    parent
  end

  @doc """
  Selects an option from a select box. The select box can be found by id, label
  text, or name. The option can be found by its text.
  """
  def select(parent, locator, option: option_text) do
    parent
    |> Node.Query.select(locator)
    |> Node.Query.option(option_text)
    |> Node.click

    parent
  end

  @doc """
  Clicks the matching link. Links can be found based on id, name, or link text.
  """
  @spec click_link(parent, locator) :: parent

  def click_link(parent, locator) do
    parent
    |> Node.Query.link(locator)
    |> Node.click

    parent
  end

  @doc """
  Clicks the matching button. Buttons can be found based on id, name, or button text.
  """
  @spec click_button(parent, locator) :: parent

  def click_button(parent, locator) do
    parent
    |> Node.Query.button(locator)
    |> Node.click

    parent
  end

  def click_on(parent, locator) do
    click_button(parent, locator)
  end

  # @doc """
  # Clears an input field. Input nodes are looked up by id, label text, or name.
  # The node can also be passed in directly.
  # """
  # @spec clear(Session.t, query) :: Session.t
  # def clear(session, query) when is_binary(query) do
  #   session
  #   |> find({:fillable_field, query})
  #   |> clear()
  # end

end
