defmodule Wallaby.Browser.FileTest do
  use Wallaby.SessionCase, async: true

  setup %{session: session} do
    page =
      session
      |> visit("forms.html")

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
    assert_raise Wallaby.QueryError, ~r/label has no 'for'/, fn ->
      attach_file(page, "File field with bad label", path: "test/support/fixtures/file.txt")
    end
  end

  test "escapes quotes", %{page: page} do
    assert attach_file(page, "I'm a file field", path: "test/support/fixtures/file.txt")
  end

  describe "attach_file/2" do
    test "works with queries", %{page: page} do
      assert page
      |> attach_file(Query.file_field("File"), path: "test/support/fixtures/file.txt")

      assert page
      |> find(Query.file_field("File"))
      |> has_value?("C:\\fakepath\\file.txt")
    end
  end
end
