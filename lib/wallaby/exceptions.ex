defmodule Wallaby.QueryError do
  defexception [:message]

  def exception(error) do
    %__MODULE__{message: error}
  end
end

defmodule Wallaby.ExpectationNotMetError do
  defexception [:message]
end

defmodule Wallaby.BadMetadataError do
  defexception [:message]
end

defmodule Wallaby.NoBaseUrlError do
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
    There was an uncaught JavaScript error:

    #{js_error}
    """

    %__MODULE__{message: msg}
  end
end

defmodule Wallaby.StaleReferenceError do
  defexception [:message]

  def exception(_) do
    msg = """
    The element you are trying to reference is stale or no longer attached to the
    DOM. The most likely reason is that it has been removed with JavaScript.

    You can typically solve this problem by using `find` to block until the DOM is in a
    stable state.
    """

    %__MODULE__{message: msg}
  end
end

defmodule Wallaby.InvalidSelectorError do
  defexception [:message]

  def exception(_) do
    %__MODULE__{message: "Shit is broken and invalid yo"}
  end
end

defmodule Wallaby.CookieError do
  defexception [:message]

  def exception(_) do
    msg = """
    The cookie you are trying to set has no domain.

    You're most likely seeing this error because you're trying to set a cookie before
    you have visited a page. You can fix this issue by calling `visit/1`
    before you call `set_cookie/3`.
    """

    %__MODULE__{message: msg}
  end
end

defmodule Wallaby.DependencyError do
  defexception [:message]

  @type t :: %__MODULE__{
          message: String.t()
        }

  def exception(msg) do
    %__MODULE__{message: msg}
  end
end
