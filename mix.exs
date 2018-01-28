defmodule Changelog.MixProject do
  use Mix.Project

  def project do
    [
      app: :changelog,
      version: "0.1.0-dev",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      elixirc_paths: ["lib", "vendor"],
      erlrc_paths: ["src", "vendor"],
      deps: deps()
    ]
  end

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp escript() do
    [
      main_module: Changelog.CLI
    ]
  end

  defp deps() do
    [
      {:httpoison, ">= 0.0.0"},
      {:hex_tar, github: "wojtekmach/hex_tar"},
      {:hex_registry, github: "wojtekmach/hex_registry"}
    ]
  end
end
