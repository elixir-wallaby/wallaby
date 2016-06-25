defmodule Wallaby.DSL.Actions do
  alias Wallaby.Node

  @type parent :: Wallaby.Node.Query.parent
  @type locator :: Wallaby.Node.Query.locator
  @type opts :: Wallaby.Node.Query.opts

  @doc """
  Fills in a "fillable" node with text. Input nodes are looked up by id, label text,
  or name.
  """
  @spec fill_in(parent, locator, opts) :: parent

  def fill_in(parent, locator, [with: value]=opts) when is_binary(value) do
    parent
    |> Node.Query.fillable_field(locator, opts)
    |> Node.fill_in(with: value)

    parent
  end

  @doc """
  Chooses a radio button based on id, label text, or name.
  """
  @spec choose(parent, locator, opts) :: parent

  def choose(parent, locator, opts\\[]) when is_binary(locator) do
    parent
    |> Node.Query.radio_button(locator, opts)
    |> Node.click

    parent
  end

  @doc """
  Checks a checkbox based on id, label text, or name.
  """
  @spec check(parent, locator, opts) :: parent

  def check(parent, locator, opts\\[]) do
    parent
    |> Node.Query.checkbox(locator, opts)
    |> Node.check

    parent
  end

  @doc """
  Unchecks a checkbox based on id, label text, or name.
  """
  @spec uncheck(parent, locator, opts) :: parent

  def uncheck(parent, locator, opts\\[]) do
    parent
    |> Node.Query.checkbox(locator, opts)
    |> Node.uncheck

    parent
  end

  @doc """
  Selects an option from a select box. The select box can be found by id, label
  text, or name. The option can be found by its text.
  """
  @spec select(parent, locator, option: String.t) :: parent

  def select(parent, locator, [option: option_text]=opts) do
    parent
    |> Node.Query.select(locator, opts)
    |> Node.Query.option(option_text, [])
    |> Node.click

    parent
  end

  @doc """
  Clicks the matching link. Links can be found based on id, name, or link text.
  """
  @spec click_link(parent, locator, opts) :: parent

  def click_link(parent, locator, opts\\[]) do
    parent
    |> Node.Query.link(locator, opts)
    |> Node.click

    parent
  end

  @doc """
  Clicks the matching button. Buttons can be found based on id, name, or button text.
  """
  @spec click_button(parent, locator, opts) :: parent

  def click_button(parent, locator, opts\\[]) do
    parent
    |> Node.Query.button(locator, opts)
    |> Node.click

    parent
  end

  @doc """
  Clicks on the matching button. Alias for `click_button`.
  """
  @spec click_on(parent, locator, opts) :: parent

  def click_on(parent, locator, opts\\[]) do
    click_button(parent, locator, opts)
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
