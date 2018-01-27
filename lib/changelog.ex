defmodule Changelog do
  defmodule Release do
    defstruct [:version, notes: []]
  end

  def parse!(string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line/1)
    |> Enum.chunk_by(&is_binary/1)
    |> maybe_remove_heading()
    |> build_releases([])
  end

  defp parse_line("## " <> version), do: Version.parse!(version)
  defp parse_line(string), do: string

  defp maybe_remove_heading([[%Version{}] | _] = lines), do: lines
  defp maybe_remove_heading([_heading | rest]), do: rest

  defp build_releases([[version], notes | rest], releases) do
    release = %Release{version: version, notes: notes}
    build_releases(rest, [release | releases])
  end

  defp build_releases([], releases) do
    Enum.reverse(releases)
  end
end
