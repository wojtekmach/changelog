defmodule Changelog.Parser do
  @moduledoc false

  def parse!(string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line/1)
    |> walk()
  end

  defp walk(lines) do
    walk(lines, nil, [])
  end

  defp walk([{version, date} | rest], nil, []) do
    walk(rest, %Changelog.Release{version: version, date: date}, [])
  end

  defp walk([{version, date} | rest], release, releases) do
    release = update_in(release.notes, &Enum.reverse/1)
    walk(rest, %Changelog.Release{version: version, date: date}, [release | releases])
  end

  defp walk([_line | rest], nil, releases) do
    walk(rest, nil, releases)
  end

  defp walk([line | rest], release, releases) do
    walk(rest, %{release | notes: [line | release.notes]}, releases)
  end

  defp walk([], release, releases) do
    release = update_in(release.notes, &Enum.reverse/1)
    Enum.reverse([release | releases])
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

      [version, date | _] ->
        case extract_version(version) do
          {:ok, version} ->
            {version, extract_date(date)}

          _ ->
            string
        end

      _ ->
        string
    end
  end

  defp extract_version("v" <> string), do: Version.parse(string)
  defp extract_version(string), do: Version.parse(string)

  defp extract_date(string) do
    string = string |> String.trim_leading("(") |> String.trim_trailing(")")

    case Date.from_iso8601(string) do
      {:ok, date} -> date
      {:error, :invalid_format} -> nil
    end
  end
end
