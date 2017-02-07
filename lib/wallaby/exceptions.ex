defmodule Wallaby.QueryError do
  defexception [:message]

  def exception(error) do
    %__MODULE__{message: error}
  end
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

defmodule Wallaby.StaleReferenceException do
  defexception [:message]

  def exception(_) do
    msg = """
    The element you are trying to reference is stale or no longer attached to the
    DOM. The most likely reason is that it has been removed with Javascript.

    You can typically solve this problem by using `find` to block until the DOM is in a
    stable state.
    """

    %__MODULE__{message: msg}
  end
end

defmodule Wallaby.InvalidSelector do
  defexception [:message]

  @spec exception(%{}) :: %__MODULE__{message: String.t}
  def exception(%{"using" => method, "value" => selector}) do
    msg = """
    The #{method} '#{selector}' is invalid.
    """

    %__MODULE__{message: msg}
  end
end
