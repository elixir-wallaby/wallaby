defmodule Wallaby.XPathTest do
  use ExUnit.Case

  import Wallaby.XPath

  test "fillable_field/2" do
    xpath = "(//textarea|//input)[not(@type='checkbox' or @type='submit' or @type='button') and (@id='name_field' or @name='name_field')]"
    assert fillable_field("name_field") == xpath
  end
end
