defmodule Wallaby.Query.ErrorMessageTest do
  use ExUnit.Case, async: true

  alias Wallaby.Query
  alias Wallaby.Query.ErrorMessage

  describe "message/1" do
    test "inclusion of binary 'text' condition when present in css query" do
      message =
        Query.css(".lcp-value", text: "322ms")
        |> Map.put(:result, [])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible element that matched the css '.lcp-value' and contained the text '322ms', but 0 visible
               elements were found.
               """)
    end

    test "no reference of 'text' condition when it isn't specified" do
      message =
        Query.css(".lcp-value")
        |> Map.put(:result, [])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible element that matched the css '.lcp-value', but 0 visible
               elements were found.
               """)
    end

    test "when the results are more than the expected count" do
      message =
        Query.css(".test", count: 1)
        |> Map.put(:result, [1, 2, 3])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible element that matched the css '.test', but 3 visible
               elements were found.
               """)
    end

    test "when the expected count is 0" do
      message =
        Query.css(".test", count: 0)
        |> Map.put(:result, [1, 2, 3])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 0 visible elements that matched the css '.test', but 3 visible
               elements were found.
               """)
    end

    test "when the result is empty" do
      message =
        Query.css(".test", count: 1)
        |> Map.put(:result, [])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible element that matched the css '.test', but 0 visible
               elements were found.
               """)
    end

    test "when the result is 1" do
      message =
        Query.css(".test", count: 3)
        |> Map.put(:result, [1])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 3 visible elements that matched the css '.test', but
               only 1 visible element was found.
               """)
    end

    test "when the result is less than the minimum result" do
      message =
        Query.css(".test", minimum: 3, maximum: 5)
        |> Map.put(:result, [1, 2])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find at least 3 visible elements that matched the css
               '.test', but only 2 visible elements were found.
               """)
    end

    test "when the result is more than the maximum" do
      message =
        Query.css(".test", minimum: 3, maximum: 5)
        |> Map.put(:result, [1, 2, 3, 4, 5, 6])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find no more than 5 visible elements that matched the css
               '.test', but 6 visible elements were found.
               """)
    end

    test "when the result has too few element for the given `at`" do
      message =
        Query.css(".test", at: 2)
        |> Map.put(:result, [1, 2])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find some visible elements that matched the css '.test'
               and return element at index 2, but only 2 visible elements were found.
               """)
    end

    test "when the result has too few checkboxes for the given `at`" do
      message =
        Query.checkbox("test", at: 3)
        |> Map.put(:result, [1, 2])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find some visible checkboxes 'test'
               and return element at index 3, but only 2 visible checkboxes were found.
               """)
    end

    test "when the result is supposed to be invisible" do
      message =
        Query.css(".test", count: 1, visible: false)
        |> Map.put(:result, [1, 2, 3])
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 invisible element that matched the css '.test', but 3
               invisible elements were found.
               """)
    end

    test "when the minimum is set less than the maximum" do
      message =
        Query.css("", minimum: 6, maximum: 5)
        |> ErrorMessage.message(:min_max)
        |> format

      assert message =~ ~r/query is invalid/
    end

    test "when the result is supposed to be selected" do
      message =
        Query.css(".test", count: 1, selected: true)
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible, selected element that matched the css '.test', but 0
               visible, selected elements were found.
               """)
    end

    test "when the result is not supposed to be selected" do
      message =
        Query.css(".test", count: 1, selected: false)
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible, unselected element that matched the css '.test', but 0
               visible, unselected elements were found.
               """)
    end

    test "with text queries" do
      message =
        Query.text("test")
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible element with the text 'test', but 0 visible elements with the text were found.
               """)

      message =
        Query.text("test", count: 2)
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 2 visible elements with the text 'test', but 0 visible elements with the text were found.
               """)
    end

    test "with value queries" do
      message =
        Query.value("test")
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible element with the attribute 'value' with value 'test', but 0 visible elements with the attribute were found.
               """)
    end

    test "with attribute key, value pair queries" do
      message =
        Query.attribute("an-attribute", "an-attribute-value")
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible element with the attribute 'an-attribute' with value 'an-attribute-value', but 0 visible elements with the attribute were found.
               """)
    end

    test "with data attribute queries" do
      message =
        Query.data("role", "data-attribute-value")
        |> ErrorMessage.message(:not_found)
        |> format

      assert message ==
               format("""
               Expected to find 1 visible element with the attribute 'data-role' with value 'data-attribute-value', but 0 visible elements with the attribute were found.
               """)
    end
  end

  describe "visibility/1" do
    test "visible query" do
      query = %Query{conditions: [visible: true]}
      assert ErrorMessage.visibility(query) == "visible"
    end

    test "invisible query" do
      query = %Query{conditions: [visible: false]}
      assert ErrorMessage.visibility(query) == "invisible"
    end
  end

  describe "method/1" do
    # test "css" do
    #   assert method(:css) == "element with css"
    # end
    #
    # test "select" do
    #   assert method(:select) == "select"
    # end
    #
    # test "fillable fields" do
    #   assert method(:fillable_field) == "text input or textarea"
    # end
    #
    # test "checkboxes" do
    #   assert method(:checkbox) == "checkbox"
    # end
    #
    # test "radio buttons" do
    #   assert method(:radio_button) == "radio button"
    # end
    #
    # test "link" do
    #   assert method(:link) == "link"
    # end
    #
    # test "xpath" do
    #   assert method(:xpath) == "element with an xpath"
    # end
    #
    # test "buttons" do
    #   assert method(:button) == "button"
    # end
    #
    # test "any unspecified locators" do
    #   assert method(:random) == "element"
    # end
    #
    # test "file field" do
    #   assert method(:file_field) == "file field"
    # end
  end

  def format(string) do
    string
    |> String.replace("\n", " ")
  end
end
