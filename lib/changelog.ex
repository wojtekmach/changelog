defmodule Changelog do
  defmodule Release do
    defstruct [:version, :date, notes: []]
  end

  def fetch(name) do
    Changelog.Fetcher.fetch(name)
  end

  def parse!(text) do
    Changelog.Parser.parse!(text)
  end
end
