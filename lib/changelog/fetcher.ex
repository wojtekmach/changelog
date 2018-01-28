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

    fetch_url("https://raw.githubusercontent.com/#{repo}/#{ref}/CHANGELOG.md")
  end

  defp fetch_releases(name) do
    body = fetch_url("https://repo.hex.pm/packages/#{name}")
    :hex_registry.decode_package(body).releases
  end

  defp fetch_tarball(name, version) do
    fetch_url("https://repo.hex.pm/tarballs/#{name}-#{version}.tar")
  end

  defp unpack_tarball(tarball) do
    case :hex_tar.unpack({:binary, tarball}) do
      {:ok, result} -> result
      {:error, reason} -> raise inspect(reason)
    end
  end

  defp fetch_url(url) do
    case HTTPoison.get!(url) do
      %{status_code: 200, body: body} ->
        body

      %{status_code: status_code} ->
        raise "error fetching #{url}: #{status_code}"
    end
  end
end
