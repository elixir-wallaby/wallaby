defmodule Wallaby.Actions.FileTest do
  use Wallaby.SessionCase, async: true

  setup %{server: server, session: session} do
    page =
      session
      |> visit(server.base_url <> "forms.html")

    {:ok, %{page: page}}
  end

  describe "attaching a file to a form" do
    test "by name", %{page: page} do
      page
      |> attach_file("file_input", path: "test/support/fixtures/file.txt")

      assert find(page, "#file_field") |> has_value?("C:\\fakepath\\file.txt")
    end

    test "by DOM ID", %{page: page} do
      page
      |> attach_file("file_field", path: "test/support/fixtures/file.txt")

      assert find(page, "#file_field") |> has_value?("C:\\fakepath\\file.txt")
    end

    test "by label", %{page: page} do
      page
      |> attach_file("File", path: "test/support/fixtures/file.txt")

      assert find(page, "#file_field") |> has_value?("C:\\fakepath\\file.txt")
    end
  end

  test "attaching a non-extant file does nothing", %{page: page} do
    page
    |> attach_file("File", path: "test/support/fixtures/fool.txt")

    assert find(page, "#file_field") |> has_value?("")
  end

  test "checks for labels without for attributes", %{page: page} do
    msg = Wallaby.QueryError.error_message(:label_with_no_for, %{locator: {:file_field, "File field with bad label"}})
    assert_raise Wallaby.QueryError, msg, fn ->
      attach_file(page, "File field with bad label", path: "test/support/fixtures/file.txt")
    end
  end

  test "escapes quotes", %{page: page} do
    assert attach_file(page, "I'm a file field", path: "test/support/fixtures/file.txt")
  end
end
