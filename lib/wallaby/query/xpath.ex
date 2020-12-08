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
  def button(query) do
    types = "./@type = 'submit' or ./@type = 'reset' or ./@type = 'button' or ./@type = 'image'"

    locator =
      ~s{(((./@id = "#{query}" or ./@name = "#{query}" or ./@value = "#{query}" or ./@alt = "#{
        query
      }" or ./@title = "#{query}" or contains(normalize-space(string(.)), "#{query}"))))}

    ~s{.//input[#{types}][#{locator}] | .//button[(not(./@type) or #{types})][#{locator}]}
  end

  @doc """
  Match any radio buttons
  """
  def radio_button(query) do
    ~s{.//input[./@type = 'radio'][(((./@id = "#{query}" or ./@name = "#{query}") or ./@placeholder = "#{
      query
    }") or ./@id = //label[contains(normalize-space(string(.)), "#{query}")]/@for)] | .//label[contains(normalize-space(string(.)), "#{
      query
    }")]//.//input[./@type = "radio"]}
  end

  @doc """
  Match any `input` or `textarea` that can be filled with text.
  Excludes any inputs with types of `submit`, `image`, `radio`, `checkbox`,
  `hidden`, or `file`.
  """
  def fillable_field(query) when is_binary(query) do
    ~s{.//*[self::input | self::textarea][not(./@type = 'submit' or ./@type = 'image' or ./@type = 'radio' or ./@type = 'checkbox' or ./@type = 'hidden' or ./@type = 'file')][(((./@id = "#{
      query
    }" or ./@name = "#{query}") or ./@placeholder = "#{query}") or ./@id = //label[contains(normalize-space(string(.)), "#{
      query
    }")]/@for)] | .//label[contains(normalize-space(string(.)), "#{query}")]//.//*[self::input | self::textarea][not(./@type = 'submit' or ./@type = 'image' or ./@type = 'radio' or ./@type = 'checkbox' or ./@type = 'hidden' or ./@type = 'file')]}
  end

  @doc """
  Match any checkboxes
  """
  def checkbox(query) do
    ~s{.//input[./@type = 'checkbox'][(((./@id = "#{query}" or ./@name = "#{query}") or ./@placeholder = "#{
      query
    }") or ./@id = //label[contains(normalize-space(string(.)), "#{query}")]/@for)] | .//label[contains(normalize-space(string(.)), "#{
      query
    }")]//.//input[./@type = "checkbox"]}
  end

  @doc """
  Match any `select` by name, id, or label.
  """
  def select(query) do
    ~s{.//select[(((./@id = "#{query}" or ./@name = "#{query}")) or ./@name = //label[contains(normalize-space(string(.)), "#{
      query
    }")]/@for or ./@id = //label[contains(normalize-space(string(.)), "#{query}")]/@for)] | .//label[contains(normalize-space(string(.)), "#{
      query
    }")]//.//select}
  end

  @doc """
  Match any `option` by visible text
  """
  def option(query) do
    ~s{.//option[normalize-space(text())="#{query}"]}
  end

  @doc """
  Matches any file field by name, id, or label
  """
  def file_field(query) do
    ~s{.//input[./@type = 'file'][(((./@id = "#{query}" or ./@name = "#{query}")) or ./@id = //label[contains(normalize-space(string(.)), "#{
      query
    }")]/@for)] | .//label[contains(normalize-space(string(.)), "#{query}")]//.//input[./@type = 'file']}
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
