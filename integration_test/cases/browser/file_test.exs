defmodule Wallaby.Integration.Browser.FileTest do
  use Wallaby.Integration.SessionCase, async: true

  import Wallaby.Query, only: [css: 1, file_field: 1]

  setup %{session: session} do
    page =
      session
      |> visit("forms.html")

    {:ok, %{page: page}}
  end

  describe "attaching a file to a form" do
    test "by name", %{page: page} do
      page
      |> attach_file(file_field("file_input"), path: "integration_test/support/fixtures/file.txt")

      find(page, css("#file_field"), fn element ->
        assert Wallaby.Element.value(element) == "C:\\fakepath\\file.txt"
      end)
    end

    test "by DOM ID", %{page: page} do
      page
      |> attach_file(file_field("file_field"), path: "integration_test/support/fixtures/file.txt")

      find(page, css("#file_field"), fn element ->
        assert Wallaby.Element.value(element) == "C:\\fakepath\\file.txt"
      end)
    end

    test "by label", %{page: page} do
      page
      |> attach_file(file_field("File"), path: "integration_test/support/fixtures/file.txt")

      find(page, css("#file_field"), fn element ->
        assert Wallaby.Element.value(element) == "C:\\fakepath\\file.txt"
      end)
    end
  end

  test "attaching a non-extant file does nothing", %{page: page} do
    page
    |> attach_file(file_field("File"), path: "integration_test/support/fixtures/fool.txt")

    find(page, css("#file_field"), fn element ->
      assert Wallaby.Element.value(element) == ""
    end)
  end

  test "checks for labels without for attributes", %{page: page} do
    assert_raise Wallaby.QueryError, ~r/label has no 'for'/, fn ->
      attach_file(page, file_field("File field with bad label"),
        path: "integration_test/support/fixtures/file.txt"
      )
    end
  end

  test "escapes quotes", %{page: page} do
    assert attach_file(page, file_field("I'm a file field"),
             path: "integration_test/support/fixtures/file.txt"
           )
  end
end
