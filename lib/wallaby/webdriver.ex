defmodule Wallaby.Webdriver do
  defstruct session: nil

  def start_link do
    %__MODULE__{session: 1}
  end

  def get(driver, action) do
    # Sucks to be on an airplane without wifi
    # HTTPoison.get("http://localhost:8910/#{action}")
    System.cmd("curl", ["-s", "http://localhost:8910/#{action}"])
  end

  def post(driver, action, params) do
  end
end

