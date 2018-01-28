defmodule Changelog.Fetcher do
  @moduledoc false

  def fetch!("github:" <> name) do
    fetch_github(name)
  end

  def fetch!(name) do
    fetch_hex(name)
  end

  defp fetch_hex(name) do
    latest_release = fetch_releases(name) |> List.last()
    tarball = fetch_tarball(name, latest_release.version)
    {_checksum, _metadata, files} = unpack_tarball(tarball)
    Map.new(files)['CHANGELOG.md']
  end

  defp fetch_github(string) do
    {repo, ref} =
      case String.split(string, ":", trim: true) do
        [repo] -> {repo, "master"}
        [repo, ref] -> {repo, ref}
      end

    url = "https://raw.githubusercontent.com/#{repo}/#{ref}/CHANGELOG.md"
    HTTPoison.get!(url).body
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
