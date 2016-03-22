defmodule Wallaby.DSL.Helpers do
  alias Wallaby.Session
  alias Wallaby.Driver

  def take_screenshot(session) do
    Driver.take_screenshot(session)
  end

  def set_window_size(session, width, height) do
    Driver.set_window_size(session, width, height)
  end

  def get_window_size(session) do
    Driver.get_window_size(session)
  end
end
