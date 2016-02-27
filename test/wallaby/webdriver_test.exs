defmodule Wallaby.WebdriverTest do
  use ExUnit.Case

  alias Wallaby.Webdriver

  test "it can start drivers" do
    driver = Webdriver.start_link
    assert driver.session
  end

  test "sending get requests" do
    driver = Webdriver.start_link
    status = Webdriver.get(driver, "/status")
    assert status
  end
end

