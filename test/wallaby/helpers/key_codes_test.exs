defmodule Wallaby.Helpers.KeyCodesTest do
  use ExUnit.Case
  import Wallaby.Helpers.KeyCodes

  test "encoding unicode values" do
    assert json([:enter]) == "{\"value\": [\"\\uE007\"]}"
  end
end
