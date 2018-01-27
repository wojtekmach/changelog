defmodule ChangelogTest do
  use ExUnit.Case

  defmacrop sigil_v({:<<>>, _, [string]}, []) do
    Macro.escape(Version.parse!(string))
  end

  test "parse!/1" do
    assert Changelog.parse!(read_fixture("simple.md")) == [
      %Changelog.Release{version: ~v"1.0.0", notes: ["* Add foo/0", "* Add bar/0"]},
      %Changelog.Release{version: ~v"0.1.0", notes: ["* Initial release"]}
    ]
  end

  defp read_fixture(path) do
    File.read!(Path.join(["test", "fixtures", path]))
  end
end
