defmodule Wallaby.Phantom.Driver.CurrentPathTest do
  use Wallaby.SessionCase, async: true

  alias Wallaby.Phantom.Driver

  setup %{session: session} do
    page =
      session
      |> visit("index.html")

    {:ok, %{page: page}}
  end

  describe "current_path!/1" do
    test "returns the current path", %{page: page} do
      assert page
      |> Driver.current_path!() == "/index.html"
    end
  end

  describe "current_url!/1" do
    test "returns the current path", %{page: page} do
      assert page
      |> Driver.current_url!() =~ ~r"^http://localhost:(.*)/index.html$"
    end
  end
end
