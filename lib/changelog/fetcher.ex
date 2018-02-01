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
    url = tarball_url(latest_release.version)
    tarball = fetch_url(url)
    {_checksum, _metadata, files} = unpack_tarball(tarball)
    files = Map.new(files)

    case Map.fetch(files, 'CHANGELOG.md') do
      {:ok, value} -> value
      :error -> {:error, {:not_found, url}}
    end
  end

  defp fetch_github(string) do
    {repo, ref} =
      case String.split(string, ":", trim: true) do
        [repo] -> {repo, "master"}
        [repo, ref] -> {repo, ref}
      end

    url = "https://raw.githubusercontent.com/#{repo}/#{ref}/CHANGELOG.md"

    case fetch_url(url) do
      {:ok, body} -> body
      {:error, 404} -> {:error, {:not_found, url}}
    end
  end

  defp fetch_releases(name) do
    body = fetch_url!("https://repo.hex.pm/packages/#{name}")
    :hex_registry.decode_package(body).releases
  end

  defp tarball_url(name, version) do
    "https://repo.hex.pm/tarballs/#{name}-#{version}.tar"
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
        {:ok, body}

      %{status_code: status_code} ->
        {:error, status_code}
    end
  end

  defp fetch_url!(url) do
    case fetch_url(url) do
      {:ok, body} -> body
      {:error, reason} -> raise "error fetching #{inspect url}, reason: #{inspect reason}"
    end
  end
end
