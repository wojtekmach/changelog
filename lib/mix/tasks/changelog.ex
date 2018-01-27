defmodule Mix.Tasks.Changelog do
  use Mix.Task

  @repo "hexpm"

  def run(args) do
    Hex.start()

    case args do
      [name] ->
        changelog = fetch_changelog(name)
        release = List.first(changelog)
        print_release(release)

      [name, version] ->
        changelog = fetch_changelog(name)
        release = Enum.find(changelog, &Version.compare(&1.version, version) == :eq)
        print_release(release)

      [name, version_from, version_to] ->
        changelog = fetch_changelog(name)
        releases = Enum.filter(changelog, &Version.compare(&1.version, version_from) in [:eq, :gt] and Version.compare(&1.version, version_to) in [:eq, :lt])
        Enum.each(releases, fn release ->
          print_release(release)
          IO.puts("")
        end)

      _ ->
        Mix.shell.error """
        Usage:

          mix changelog PACKAGE
          mix changelog PACKAGE VERSION
          mix changelog PACKAGE VERSION_FROM VERSION_TO

        """
    end
  end

  defp print_release(release) do
    if release.date do
      IO.puts "## #{release.version} - #{release.date}"
    else
      IO.puts "## #{release.version}"
    end

    IO.puts ""
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
end
