defmodule Changelog do
  defmodule Release do
    defstruct [:version, :date, notes: []]
  end

  def parse!(string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line/1)
    |> Enum.chunk_by(&is_binary/1)
    |> maybe_remove_heading()
    |> build_releases([])
  end

  defp parse_line("## " <> string), do: extract_version_date(string)
  defp parse_line(string), do: string

  defp extract_version_date(string) do
    case String.split(string, " ") do
      [version] ->
        case extract_version(version) do
          {:ok, version} ->
            {version, nil}

          _ ->
            string
        end

      [version, date] ->
        case extract_version(version) do
          {:ok, version} ->
            {version, extract_date(date)}

          _ ->
            string
        end
    end
  end

  defp extract_version("v" <> string), do: Version.parse(string)
  defp extract_version(string), do: Version.parse(string)

  defp extract_date(string) do
    string
    |> String.trim_leading("(")
    |> String.trim_trailing(")")
    |> Date.from_iso8601!()
  end

  defp maybe_remove_heading([[%Version{}] | _] = lines), do: lines
  defp maybe_remove_heading([_heading | rest]), do: rest

  defp build_releases([[{version, date}], notes | rest], releases) do
    release = %Release{version: version, date: date, notes: notes}
    build_releases(rest, [release | releases])
  end

  defp build_releases([], releases) do
    Enum.reverse(releases)
  end
end
