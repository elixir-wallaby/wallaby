defmodule Wallaby.Phantom do
  def capabilities(opts) do
    default_capabilities
    |> Map.merge(user_agent_capability(opts[:user_agent]))
  end

  def default_capabilities do
    %{
      javascriptEnabled: false,
      version: "",
      rotatable: false,
      takesScreenshot: true,
      cssSelectorsEnabled: true,
      browserName: "phantomjs",
      nativeEvents: false,
      platform: "ANY"
    }
  end

  def user_agent do
    "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/538.1 (KHTML, like Gecko) PhantomJS/2.1.1 Safari/538.1"
  end

  def user_agent_capability(nil), do: %{}
  def user_agent_capability(ua) do
    %{"phantomjs.page.settings.userAgent" => ua}
  end
end
