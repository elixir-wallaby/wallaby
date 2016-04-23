defmodule Wallaby.AmbiguousMatch do
  defexception [:message]
end

defmodule Wallaby.ElementNotFound do
  defexception [:message]
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
