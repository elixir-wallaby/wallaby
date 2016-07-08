defmodule Wallaby.AmbiguousMatch do
  defexception [:message]

  def exception({locator, elements, count}) do
    %__MODULE__{message: msg(locator, elements, count)}
  end

  def msg({:css, query}, elements, count) do
    base_msg("the css", query, elements, count)
  end
  def msg({_, query}, elements, count) do
    base_msg("the locator", query, elements, count)
  end

  def base_msg(locator, query, elements, count) do
    """
    The #{locator}: '#{query}' is ambiguous. It was found #{times(length(elements))}
    but it should have been found #{times(count)}.

    If you expect to find the selector #{times(length(elements))} then you
    should include the `count: #{length(elements)}` option in your finder.
    """
  end

  defp times(1), do: "1 time"
  defp times(count), do: "#{count} times"
end

defmodule Wallaby.ElementNotFound do
  defexception [:message]

  def exception(locator) do
    %__MODULE__{message: msg(locator)}
  end

  def msg({:css, query}), do: base_msg("an element with the css", query)
  def msg({:select, query}), do: base_msg("a select", query)
  def msg({:fillable_field, query}), do: base_msg("a text input or textarea", query)
  def msg({:checkbox, query}), do: base_msg("a checkbox", query)
  def msg({:radio_button, query}), do: base_msg("a radio button", query)
  def msg({:button, query}), do: base_msg("a button", query)
  def msg({:link, query}), do: base_msg("a link", query)
  def msg({:xpath, query}), do: base_msg("an element with an xpath", query)
  def msg({_, query}), do: base_msg("an element", query)

  def base_msg(locator, query) do
    """
    Could not find #{locator} that matched: '#{query}'
    """
  end
end

defmodule Wallaby.ElementFound do
  defexception [:message]

  def exception(locator) do
    %__MODULE__{message: msg(locator)}
  end

  def msg({:css, query}) do
    base_msg("the css", query)
  end
  def msg({_, query}) do
    base_msg("the locator", query)
  end

  def base_msg(locator, query) do
    """
    The element with #{locator}: '#{query}' should not have been found but was
    found.
    """
  end
end

defmodule Wallaby.ExpectationNotMet do
  defexception [:message]
end

defmodule Wallaby.InvisibleElement do
  defexception [:message]

  def exception(locator) do
    %__MODULE__{message: msg(locator)}
  end

  def msg({:css, query}) do
    base_msg("the css", query)
  end
  def msg({_, query}) do
    base_msg("the locator", query)
  end

  def base_msg(locator, query) do
    """
    An element with #{locator}: '#{query}' was found but its not visible to a
    real user.

    If you expect the element to be invisible to the user then you should
    include the `visible: false` option in your finder.
    """
  end
end

defmodule Wallaby.VisibleElement do
  defexception [:message]

  def exception(locator) do
    %__MODULE__{message: msg(locator)}
  end

  def msg({:css, query}) do
    base_msg("the css", query)
  end
  def msg({_, query}) do
    base_msg("the locator", query)
  end

  def base_msg(locator, query) do
    """
    An element with #{locator}: '#{query}' should not have been visible but was.

    If you expect the element to be visible to the user then you should
    remove the `visible: false` option from your finder.
    """
  end
end

defmodule Wallaby.BadMetadata do
  defexception [:message]
end

defmodule Wallaby.NoBaseUrl do
  defexception [:message]

  def exception(relative_path) do
    msg = """
    You called visit with #{relative_path}, but did not set a base_url.
    Set this in config/test.exs or in test/test_helper.exs:

      Application.put_env(:wallaby, :base_url, "http://localhost:4001")

    If using Phoenix, you can use the url from your endpoint:

      Application.put_env(:wallaby, :base_url, YourApplication.Endpoint.url)
    """

    %__MODULE__{message: msg}
  end
end

defmodule Wallaby.BadHTML do
  defexception [:message]

  def exception(error) do
    %__MODULE__{message: msg(error)}
  end

  def msg({:label_with_no_for, {type, label_text}}) do
    """
    The text '#{label_text}' matched a label but the label has no 'for'
    attribute and can't be used to find the correct #{type(type)}.

    You can fix this by including the `for="YOUR_INPUT_ID"` attribute on the
    appropriate label.
    """
  end

  def msg({:label_does_not_find_field, {type, label_text}, for_text}) do
    """
    The text '#{label_text}' matched a label but the label's 'for' attribute
    doesn't match the id of any #{type(type)}.

    Make sure that id on your #{type(type)} is `id="#{for_text}"`.
    """
  end

  def type(:radio_button), do: "radio button"
  def type(:fillable_field), do: "text input or textarea"
  def type(:checkbox), do: "checkbox"
  def type(:select), do: "select"
  def type(_), do: "field"
end
