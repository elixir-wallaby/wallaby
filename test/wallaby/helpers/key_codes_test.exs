defmodule Wallaby.Helpers.KeyCodesTest do
  use ExUnit.Case, async: true

  import Wallaby.Helpers.KeyCodes

  test "encoding unicode values" do
    assert json([:enter]) == "{\"value\": [\"\\uE007\"]}"
    assert json([:shift, :enter]) == "{\"value\": [\"\\uE008\",\"\\uE007\"]}"
  end
end
