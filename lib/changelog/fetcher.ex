defmodule Changelog.Fetcher do
  @moduledoc false

  def fetch_changelog("github:" <> name) do
    HTTPoison.start()
    fetch_github_changelog(name)
  end

  def fetch_changelog(name) do
    HTTPoison.start()
    fetch_hex_changelog(name)
  end

  defp fetch_hex_changelog(name) do
    latest_release = fetch_releases(name) |> List.last()
    tarball = fetch_tarball(name, latest_release.version)
    {_checksum, _metadata, files} = unpack_tarball(tarball)
    text = Map.new(files)['CHANGELOG.md']
    Changelog.parse!(text)
  end

  defp fetch_github_changelog(string) do
    {repo, ref} =
      case String.split(string, ":", trim: true) do
        [repo] -> {repo, "master"}
        [repo, ref] -> {repo, ref}
      end

    url = "https://raw.githubusercontent.com/#{repo}/#{ref}/CHANGELOG.md"
    body = HTTPoison.get!(url).body
    Changelog.parse!(body)
  end

  defp fetch_releases(name) do
    url = "https://repo.hex.pm/packages/#{name}"
    body = HTTPoison.get!(url).body
    :hex_registry.decode_package(body).releases
  end

  defp fetch_tarball(name, version) do
    url = "https://repo.hex.pm/tarballs/#{name}-#{version}.tar"
    HTTPoison.get!(url).body
  end

  defp unpack_tarball(tarball) do
    case :hex_tar.unpack({:binary, tarball}) do
      {:ok, result} -> result
      {:error, reason} -> raise inspect(reason)
    end
  end
end
