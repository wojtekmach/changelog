defmodule Mix.Tasks.Changelog do
  use Mix.Task

  @repo "hexpm"

  def run(args) do
    Hex.start()
    check_hex_version()

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
        Mix.raise("""
        Usage:

          mix changelog PACKAGE
          mix changelog PACKAGE latest
          mix changelog PACKAGE VERSION
          mix changelog PACKAGE VERSION_FROM VERSION_TO
          mix changelog PACKAGE VERSION_FROM latest

        """)
    end
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

  defp fetch_changelog(name) do
    latest_release = fetch_releases(name) |> List.last()
    tarball = fetch_tarball(name, latest_release.version)
    {_metadata, _checksum, files} = unpack_tarball(tarball)
    text = Map.new(files)["CHANGELOG.md"]
    Changelog.parse!(text)
  end

  # FIXME: do not use Hex private APIs!
  defp fetch_releases(name) do
    {:ok, {200, body, _headers}} = Hex.Repo.get_package(@repo, name, nil)

    body
    |> :zlib.gunzip()
    |> Hex.Repo.verify(@repo)
    |> Hex.Repo.decode()
  end

  # FIXME: do not use Hex private APIs!
  defp fetch_tarball(name, version) do
    {:ok, {200, body, _headers}} = Hex.Repo.get_tarball(@repo, name, version, nil)
    body
  end

  # FIXME: do not use Hex private APIs!
  defp unpack_tarball(tarball) do
    Hex.unpack_tar!({:binary, tarball}, :memory)
  end

  defp check_hex_version() do
    {:ok, vsn} = :application.get_key(:hex, :vsn)

    unless Version.match?("#{vsn}", "~> 0.17.1") do
      Mix.raise("""
      changelog requires Hex ~> 0.17.1, got: #{vsn}. Please upgrade!

      Also, stay tuned for a new changelog release that is not naughy and does not use Hex private APIs anymore!
      """)
    end
  end
end
