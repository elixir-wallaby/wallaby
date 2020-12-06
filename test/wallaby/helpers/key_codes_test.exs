defmodule Wallaby.Helpers.KeyCodesTest do
  use ExUnit.Case, async: true

  import Wallaby.Helpers.KeyCodes

  test "encoding unicode values as JSON" do
    assert json([:enter]) == "{\"value\": [\"\\uE007\"]}"
    assert json([:shift, :enter]) == "{\"value\": [\"\\uE008\",\"\\uE007\"]}"
  end

  test "encoding values with strings as JSON" do
    assert json(["te", :enter]) == "{\"value\": [\"t\",\"e\",\"\\uE007\"]}"
  end

  test "ensuring chars returns list of strings" do
    assert chars([:enter]) == ["\\uE007"]
    assert chars(:enter) == ["\\uE007"]
    assert chars([:shift, :enter]) == ["\\uE008", "\\uE007"]
    assert chars(["John", :tab, "Smith"]) == ["John", "\\uE004", "Smith"]
  end

  test "ensuring chars returns file paths as file paths" do
    assert chars("/some/path/to/foo.txt") == ["/some/path/to/foo.txt"]
    files = ["/path/to/foo.txt", "/path/to/bar.txt"]
    assert chars(files) == files
  end
end
