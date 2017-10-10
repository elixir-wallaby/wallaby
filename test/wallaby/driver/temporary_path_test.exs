defmodule Wallaby.Driver.TemporaryPathTest do
  use ExUnit.Case, async: true

  alias Wallaby.Driver.TemporaryPath

  describe "generate/1" do
    test "generates a temporary path in System.tmp_dir! by default" do
      assert TemporaryPath.generate() =~ ~r(^#{System.tmp_dir()})
    end

    test "generates a temporary path in the given base dir" do
      base_dir = "/srv/wallaby"

      assert TemporaryPath.generate(base_dir) =~ ~r(^#{base_dir})
    end
  end
end
