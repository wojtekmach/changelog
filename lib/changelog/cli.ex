defmodule Changelog.CLI do
  @moduledoc false

  @usage """
  Usage:

      mix changelog PACKAGE
      mix changelog PACKAGE latest
      mix changelog PACKAGE VERSION
      mix changelog PACKAGE VERSION_FROM VERSION_TO
      mix changelog PACKAGE VERSION_FROM latest

  PACKAGE can also be:

      github:ORG/REPO
      github:ORG/REPO:REF
  """

  def main(args) do
    HTTPoison.start()

    case args do
      [name] ->
        changelog = fetch_changelog(name)
        print_releases(changelog)

      [name, "latest"] ->
        changelog = fetch_changelog(name)
        release = List.first(changelog)
        print_release(release)

      [name, version] ->
        changelog = fetch_changelog(name)
        release = Enum.find(changelog, &(Version.compare(&1.version, version) == :eq))
        print_release(release)

      [name, version_from, "latest"] ->
        changelog = fetch_changelog(name)

        releases =
          Enum.filter(changelog, &(Version.compare(&1.version, version_from) in [:eq, :gt]))

        print_releases(releases)

      [name, version_from, version_to] ->
        changelog = fetch_changelog(name)
        releases = Enum.filter(changelog, &match_version?(&1, version_from, version_to))
        print_releases(releases)

      _ ->
        IO.puts(@usage)
        exit({:shutdown, 1})
    end
  end

  defp fetch_changelog(name) do
    name
    |> Changelog.fetch!()
    |> Changelog.parse!()
  end

  defp match_version?(release, version_from, version_to) do
    Version.compare(release.version, version_from) in [:eq, :gt] and
      Version.compare(release.version, version_to) in [:eq, :lt]
  end

  defp print_releases(releases) do
    Enum.each(releases, fn release ->
      print_release(release)
      IO.puts("")
    end)
  end

  defp print_release(release) do
    if release.date do
      IO.puts("## #{release.version} - #{release.date}")
    else
      IO.puts("## #{release.version}")
    end

    IO.puts("")
    Enum.each(release.notes, &IO.puts(&1))
  end
end
