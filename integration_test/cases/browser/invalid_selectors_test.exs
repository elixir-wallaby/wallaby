defmodule Wallaby.Integration.Browser.InvalidSelectorsTest do
  use Wallaby.Integration.SessionCase, async: true

  import Wallaby.Query, only: [css: 1]

  describe "with an invalid selector state" do
    test "find returns an exception", %{session: session} do
      assert_raise Wallaby.QueryError, ~r/The css 'checkbox:foo' is not a valid query/, fn ->
        find(session, css("checkbox:foo"))
      end
    end

    test "assert_has raises an exception", %{session: session} do
      assert_raise Wallaby.QueryError, ~r/The css 'checkbox:foo' is not a valid query/, fn ->
        assert_has(session, css("checkbox:foo"))
      end
    end

    test "refute_has raises an exception", %{session: session} do
      assert_raise Wallaby.QueryError, ~r/The css 'checkbox:foo' is not a valid query/, fn ->
        refute_has(session, css("checkbox:foo"))
      end
    end
  end
end
