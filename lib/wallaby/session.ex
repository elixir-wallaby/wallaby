defmodule Wallaby.Session do
  @moduledoc """
  Struct containing details about the webdriver session.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          session_url: String.t(),
          url: String.t(),
          server: pid | :none,
          screenshots: list,
          driver: module,
          capabilities: map(),
          wdc_config: WebDriverClient.Config.t() | nil,
          wdc_session: WebDriverClient.Session.t() | nil
        }

  defstruct [
    :id,
    :url,
    :session_url,
    :driver,
    :capabilities,
    :wdc_config,
    :wdc_session,
    server: :none,
    screenshots: []
  ]
end
