defmodule Changelog.Fetcher do
  @moduledoc false

  def fetch("github:" <> name) do
    fetch_github(name)
  end

  def fetch(name) do
    fetch_hex(name)
  end

  defp fetch_hex(name) do
    case fetch_releases(name) do
      {:ok, releases} ->
        latest_release = List.last(releases)
        url = tarball_url(name, latest_release.version)

        case fetch_url(url) do
          {:ok, tarball} ->
            {_checksum, _metadata, files} = unpack_tarball(tarball)
            files = Map.new(files)

            case Map.fetch(files, 'CHANGELOG.md') do
              {:ok, value} ->
                {:ok, value}

              :error ->
                {:error, {:hex, :changelog_not_found, url}}
            end
        end

      {:error, error} when error in [403, 404] ->
        {:error, {:hex, :package_not_found, package_url(name)}}

      {:error, error} ->
        {:error, {:hex, error, package_url(name)}}
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
      {:ok, body} -> {:ok, body}
      {:error, 404} -> {:error, {:github, :not_found, url}}
      {:error, other} -> {:error, {:github, other, url}}
    end
  end

  defp fetch_releases(name) do
    with {:ok, body} <- fetch_url(package_url(name)) do
      {:ok, :hex_registry.decode_package(body).releases}
    end
  end

  defp package_url(name) do
    "https://repo.hex.pm/packages/#{name}"
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
end
