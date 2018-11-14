defmodule RippleWeb.ChatHelperTest do
  use Ripple.DataCase

  alias RippleWeb.Helpers.ChatHelper

  describe "ChatHelper" do
    test "process/1 successfully processes only text" do
      text = "This is a test"
      assert [%{type: "text", value: text}] == ChatHelper.process(text)
    end

    test "process/1 successfully processes only a url starting with https" do
      text = "https://ripple.fm"
      assert [%{type: "link", value: text}] == ChatHelper.process(text)
    end

    test "process/1 successfully processes only a url starting with www" do
      text = "www.ripple.fm"
      assert [%{type: "link", value: text}] == ChatHelper.process(text)
    end

    test "process/1 successfully processes multiple urls" do
      text = "https://ripple.fm www.ripple.fm"

      assert [
               %{type: "link", value: "https://ripple.fm"},
               %{type: "link", value: "www.ripple.fm"}
             ] == ChatHelper.process(text)
    end

    test "process/1 successfully processes only a mention" do
      text = "@tester"
      assert [%{type: "mention", value: text}] == ChatHelper.process(text)
    end

    test "process/1 successfully processes multiple mentions" do
      text = "@tester @admin"

      assert [%{type: "mention", value: "@tester"}, %{type: "mention", value: "@admin"}] ==
               ChatHelper.process(text)
    end

    test "process/1 successfully processes a message with text, url, and a mention" do
      text = "look at this link https://ripple.fm @tester"

      assert [
               %{type: "text", value: "look at this link"},
               %{type: "link", value: "https://ripple.fm"},
               %{type: "mention", value: "@tester"}
             ] == ChatHelper.process(text)
    end

    test "process/1 successfully processes a message with text, link, and text" do
      text = "look at https://ripple.fm test 123"

      assert [
               %{type: "text", value: "look at"},
               %{type: "link", value: "https://ripple.fm"},
               %{type: "text", value: "test 123"}
             ] == ChatHelper.process(text)
    end
  end
end
