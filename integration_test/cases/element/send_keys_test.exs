defmodule Wallaby.Integration.Element.SendKeysTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    {:ok, page: visit(session, "forms.html")}
  end

  @name_field Query.text_field("Name")
  @email_field Query.text_field("email_field")

  describe "send_keys/2" do
    test "sends keys to the specified element", %{page: page} do
      page
      |> click(@email_field)
      |> find(@name_field, fn element ->
        assert element
               |> Element.send_keys("Chris")
               |> Element.value() == "Chris"
      end)
      |> find(@email_field, fn email ->
        assert email
               |> Element.value() == ""
      end)
    end
  end
end
