defmodule Wallaby.Chrome.Chromedriver.ReadinessChecker do
  @moduledoc false

  alias WebDriverClient.Config
  alias WebDriverClient.ServerStatus

  @type url :: String.t()

  @spec wait_until_ready(url, non_neg_integer()) :: :ok
  def wait_until_ready(base_url, delay \\ 200)
      when is_binary(base_url) and is_integer(delay) and delay >= 0 do
    if ready?(base_url) do
      :ok
    else
      Process.sleep(delay)
      wait_until_ready(base_url, delay)
    end
  end

  @spec ready?(url) :: boolean
  defp ready?(base_url) do
    base_url
    |> build_config()
    |> WebDriverClient.fetch_server_status()
    |> case do
      {:ok, %ServerStatus{ready?: true}} -> true
      _ -> false
    end
  end

  # @spec build_config(url) :: Config.t()
  def build_config(base_url) do
    # Chromedriver responds to the status endpoint check in w3c
    # protocol.
    Config.build(base_url,
      protocol: :w3c,
      http_client_options: hackney_options()
    )
  end

  @default_httpoison_options [hackney: [pool: :wallaby_pool]]

  # The :hackney_options key in the environment is misnamed. These
  # are actually the options as they're passed to HTTPoison.
  @spec hackney_options() :: list
  defp hackney_options do
    :wallaby
    |> Application.get_env(:hackney_options, @default_httpoison_options)
    |> Keyword.get(:hackney, [])
  end
end
