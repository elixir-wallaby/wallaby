defmodule Wallaby.Driver.TemporaryPath do
  @moduledoc false

  @spec generate(String.t()) :: String.t()
  def generate(base_path \\ System.tmp_dir!()) do
    dirname =
      0x100000000
      |> :rand.uniform()
      |> Integer.to_string(36)
      |> String.downcase()

    Path.join(base_path, dirname)
  end
end
