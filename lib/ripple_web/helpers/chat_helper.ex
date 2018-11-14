defmodule RippleWeb.Helpers.ChatHelper do
  def process(text) when is_binary(text) do
    text |> String.split(" ") |> Enum.map(&parse/1) |> Enum.reduce([], &merge_types/2)
  end

  defp merge_types(current, []), do: [current]

  defp merge_types(%{type: "text", value: value} = current, list) do
    {last, new_list} = List.pop_at(list, Enum.count(list) - 1)

    new_last =
      case last do
        %{type: "text", value: last_val} -> [%{type: "text", value: "#{last_val} #{value}"}]
        _ -> [last, current]
      end

    new_list ++ new_last
  end

  defp merge_types(current, list), do: list ++ [current]

  defp parse("http" <> _link = url), do: %{type: "link", value: url}

  defp parse("www." <> _link = url), do: %{type: "link", value: url}

  defp parse("@" <> _username = mention), do: %{type: "mention", value: mention}

  defp parse(text), do: %{type: "text", value: text}
end
