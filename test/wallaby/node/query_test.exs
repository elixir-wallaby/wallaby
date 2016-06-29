defmodule Wallaby.Node.QueryTest do
  use Wallaby.SessionCase, async: true

  @moduletag :focus

  setup %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "forms.html")

    {:ok, page: page}
  end

  test "find_field/3 checks for labels without for attributes", %{page: page} do
    assert_raise Wallaby.BadHTML, fn ->
      fill_in(page, "Input with bad label", with: "Test")
    end
  end

  test "find_field/3 checks for mismatched ids on labels", %{page: page} do
    assert_raise Wallaby.BadHTML, fn ->
      fill_in(page, "Input with bad id", with: "Test")
    end
  end
end
