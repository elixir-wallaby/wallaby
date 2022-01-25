defmodule Wallaby.Query.XPath do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Readability.MaxLineLength

  @type query :: String.t()
  @type xpath :: String.t()
  @type name :: query
  @type id :: query
  @type label :: query

  @doc """
  XPath for links

  This xpath is gracious ripped from capybara via
  https://github.com/jnicklas/xpath/blob/master/lib/xpath/html.rb
  """
  def link(lnk) do
    ~s{.//a[./@href][(((./@id = "#{lnk}" or contains(normalize-space(string(.)), "#{lnk}")) or contains(./@title, "#{
      lnk
    }")) or .//img[contains(./@alt, "#{lnk}")])]}
  end

  @doc """
  Match any clickable buttons
  """
  def button(selector) do
    types = "./@type = 'submit' or ./@type = 'reset' or ./@type = 'button' or ./@type = 'image'"

    locator =
      ~s{(((./@id = "#{selector}" or ./@name = "#{selector}" or ./@value = "#{selector}" or ./@alt = "#{
        selector
      }" or ./@title = "#{selector}" or contains(normalize-space(string(.)), "#{selector}"))))}

    ~s{.//input[#{types}][#{locator}] | .//button[(not(./@type) or #{types})][#{locator}]}
  end

  @doc """
  Match any radio buttons
  """
  def radio_button(selector) do
    ~s{.//input[./@type = 'radio'][(((./@id = "#{selector}" or ./@name = "#{selector}") or ./@placeholder = "#{
      selector
    }") or ./@id = //label[contains(normalize-space(string(.)), "#{selector}")]/@for)] | .//label[contains(normalize-space(string(.)), "#{
      selector
    }")]//.//input[./@type = "radio"]}
  end

  @doc """
  Match any `input` or `textarea` that can be filled with text.
  Excludes any inputs with types of `submit`, `image`, `radio`, `checkbox`,
  `hidden`, or `file`.
  """
  def fillable_field(selector) when is_binary(selector) do
    ~s{.//*[self::input | self::textarea][not(./@type = 'submit' or ./@type = 'image' or ./@type = 'radio' or ./@type = 'checkbox' or ./@type = 'hidden' or ./@type = 'file')][(((./@id = "#{
      selector
    }" or ./@name = "#{selector}") or ./@placeholder = "#{selector}") or ./@id = //label[contains(normalize-space(string(.)), "#{
      selector
    }")]/@for)] | .//label[contains(normalize-space(string(.)), "#{selector}")]//.//*[self::input | self::textarea][not(./@type = 'submit' or ./@type = 'image' or ./@type = 'radio' or ./@type = 'checkbox' or ./@type = 'hidden' or ./@type = 'file')]}
  end

  @doc """
  Match any checkboxes
  """
  def checkbox(selector) do
    ~s{.//input[./@type = 'checkbox'][(((./@id = "#{selector}" or ./@name = "#{selector}") or ./@placeholder = "#{
      selector
    }") or ./@id = //label[contains(normalize-space(string(.)), "#{selector}")]/@for)] | .//label[contains(normalize-space(string(.)), "#{
      selector
    }")]//.//input[./@type = "checkbox"]}
  end

  @doc """
  Match any `select` by name, id, or label.
  """
  def select(selector) do
    ~s{.//select[(((./@id = "#{selector}" or ./@name = "#{selector}")) or ./@name = //label[contains(normalize-space(string(.)), "#{
      selector
    }")]/@for or ./@id = //label[contains(normalize-space(string(.)), "#{selector}")]/@for)] | .//label[contains(normalize-space(string(.)), "#{
      selector
    }")]//.//select}
  end

  @doc """
  Match any `option` by visible text
  """
  def option(selector) do
    ~s{.//option[normalize-space(text())="#{selector}"]}
  end

  @doc """
  Matches any file field by name, id, or label
  """
  def file_field(selector) do
    ~s{.//input[./@type = 'file'][(((./@id = "#{selector}" or ./@name = "#{selector}")) or ./@id = //label[contains(normalize-space(string(.)), "#{
      selector
    }")]/@for)] | .//label[contains(normalize-space(string(.)), "#{selector}")]//.//input[./@type = 'file']}
  end

  @doc """
  Matches any element by its inner text.
  """
  def text(selector) do
    ~s{.//*[contains(normalize-space(text()), "#{selector}")]}
  end

  @doc """
  Matches any element by its attribute name and value pair.
  """
  def attribute(name, value) do
    ~s{.//*[./@#{name} = "#{value}"]}
  end
end
