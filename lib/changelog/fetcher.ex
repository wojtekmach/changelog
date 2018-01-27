defmodule Changelog.Fetcher do
  @moduledoc false
  @repo "hexpm"

  def fetch_changelog("github:" <> name) do
    check_hex_version()
    fetch_github_changelog(name)
  end
  def fetch_changelog(name) do
    check_hex_version()
    fetch_hex_changelog(name)
  end

  defp fetch_hex_changelog(name) do
    latest_release = fetch_releases(name) |> List.last()
    tarball = fetch_tarball(name, latest_release.version)
    {_metadata, _checksum, files} = unpack_tarball(tarball)
    text = Map.new(files)["CHANGELOG.md"]
    Changelog.parse!(text)
  end

  # FIXME: do not use Hex private APIs!
  defp fetch_github_changelog(string) do
    {repo, ref} =
      case String.split(string, ":", trim: true) do
        [repo] -> {repo, "master"}
        [repo, ref] -> {repo, ref}
      end

    url = "https://raw.githubusercontent.com/#{repo}/#{ref}/CHANGELOG.md"
    {:ok, {200, body, _}} = Hex.HTTP.request(:get, url, %{}, nil)
    Changelog.parse!(body)
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
    Hex.start()
    {:ok, vsn} = :application.get_key(:hex, :vsn)

    unless Version.match?("#{vsn}", "~> 0.17.1") do
      Mix.raise("changelog requires Hex ~> 0.17.1, got: #{vsn}. Please upgrade!")
    end
  end
end
