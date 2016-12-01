defmodule Wallaby.QueryError do
  defexception [:message]

  alias Wallaby.Node.Query

  @doc false
  @spec exception(Query.t) :: Exception.t

  def exception(query) do
    msg =
      query
      |> errors
      |> hd

    %__MODULE__{message: msg}
  end

  @doc """
  Generates an error message based on errors present in the query struct.
  If there are multiple errors in a query then we'll only show the first one.
  Because of this errors always need to be in order from most specific to most
  generic. That way we always show the most specific error to the user.
  """
  @spec errors(Query.t) :: String.t

  def errors(%{errors: errors}=query) do
    errors
    |> hd
    |> error_message(query)
    |> List.wrap
  end

  @doc """
  Compose an error message based on the error type and query information
  """
  @spec error_message(atom(), %{}) :: String.t

  def error_message(:not_found, %{locator: locator, conditions: opts}) do
    msg = "Could not find any #{visibility(opts)} #{method(locator)} that matched: '#{expression(locator)}'"
    [msg] ++ conditions(opts)
    |> Enum.join(" and ")
  end
  def error_message(:found, %{locator: locator}) do
    """
    The element with #{method locator}: '#{expression locator}' should not have been found but was
    found.
    """
  end
  def error_message(:visible, %{locator: locator}) do
    """
    The #{method(locator)} that matched: '#{expression(locator)}' should not have been visible but was.

    If you expect the element to be visible to the user then you should
    remove the `visible: false` option from your finder.
    """
  end
  def error_message(:ambiguous, %{locator: locator, result: elements, conditions: opts}) do
    count = Keyword.get(opts, :count)

    """
    The #{method(locator)} that matched: '#{expression(locator)}' was found but
    the results are ambiguous. It was found #{times(length(elements))} but it
    should have been found #{times(count)}.

    If you expect to find the selector #{times(length(elements))} then you
    should include the `count: #{length(elements)}` option in your finder.
    """
  end
  def error_message(:not_visible, %{locator: locator}) do
    """
    The #{method locator}: '#{expression locator}' was found but its not visible to a
    real user.

    If you expect the element to be invisible to the user then you should
    include the `visible: false` option in your finder.
    """
  end
  def error_message(:label_with_no_for, %{locator: locator}) do
    """
    The text '#{expression locator}' matched a label but the label has no 'for'
    attribute and can't be used to find the correct #{method(locator)}.

    You can fix this by including the `for="YOUR_INPUT_ID"` attribute on the
    appropriate label.
    """
  end
  def error_message({:label_does_not_find_field, for_text}, %{locator: locator}) do
    """
    The text '#{expression locator}' matched a label but the label's 'for' attribute
    doesn't match the id of any #{method(locator)}.

    Make sure that id on your #{method(locator)} is `id="#{for_text}"`.
    """
  end
  def error_message(:button_with_bad_type, %{locator: locator}) do
    """
    The text '#{expression locator}' matched a button but the button has an invalid 'type' attribute.

    You can fix this by including `type="[submit|reset|button|image]"` on the appropriate button.
    """
  end

  @doc """
  Extracts the locator method from the locator and converts it into a human
  readable format
  """
  @spec method({atom(), any()}) :: String.t

  def method({:css, _}), do: "element with css"
  def method({:select, _}), do: "select"
  def method({:fillable_field, _}), do: "text input or textarea"
  def method({:checkbox, _}), do: "checkbox"
  def method({:radio_button, _}), do: "radio button"
  def method({:link, _}), do: "link"
  def method({:xpath, _}), do: "element with an xpath"
  def method({:button, _}), do: "button"
  def method({:file_field, _}), do: "file field"
  def method(_), do: "element"

  @doc """
  Extracts the expression from the locator.
  """
  @spec expression({any(), String.t}) :: String.t

  def expression({_, expr}) when is_binary(expr), do: expr

  @doc """
  Generates failure conditions based on query conditions.
  """
  @spec conditions(Keyword.t) :: list(String.t)

  def conditions(opts) do
    opts
    |> Keyword.delete(:visible)
    |> Keyword.delete(:count)
    |> Enum.map(&condition/1)
    |> Enum.reject(& &1 == nil)
  end

  @doc """
  Converts a condition into a human readable failure message.
  """
  @spec condition({atom(), String.t}) :: String.t | nil

  def condition({:text, text}) when is_binary(text) do
    "text: '#{text}'"
  end
  def condition(_), do: nil

  @doc """
  Converts the visibilty attribute into a human readable form.
  """
  @spec visibility(Keyword.t) :: String.t

  def visibility(opts) do
    if Keyword.get(opts, :visible) do
      "visible"
    else
      "invisible"
    end
  end

  defp times(1), do: "1 time"
  defp times(count), do: "#{count} times"
end

defmodule Wallaby.ExpectationNotMet do
  defexception [:message]
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

defmodule Wallaby.JSError do
  defexception [:message]

  def exception(js_error) do
    msg = """
    There was an uncaught javascript error:

    #{js_error}
    """

    %__MODULE__{message: msg}
  end
end
