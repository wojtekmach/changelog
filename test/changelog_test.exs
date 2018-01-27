defmodule ChangelogTest do
  use ExUnit.Case

  defmacrop sigil_v({:<<>>, _, [string]}, []) do
    Macro.escape(Version.parse!(string))
  end

  test "parse!/1" do
    string = """
    # Changelog

    ## Highlights

    Foo

    ## 1.0.0-dev

    * Add foo/0
    * Add bar/0

    ## v0.1.0 (2018-01-01)

    * Initial release
    """

    assert Changelog.parse!(string) == [
             %Changelog.Release{
               version: ~v"1.0.0-dev",
               date: nil,
               notes: ["* Add foo/0", "* Add bar/0"]
             },
             %Changelog.Release{
               version: ~v"0.1.0",
               date: ~D"2018-01-01",
               notes: ["* Initial release"]
             }
           ]
  end

  test "ecto" do
    releases = Changelog.parse!(read_fixture("ecto.md"))

    assert Enum.map(releases, & &1.version) == [
             ~v"2.2.8",
             ~v"2.2.7",
             ~v"2.2.6",
             ~v"2.2.5",
             ~v"2.2.4",
             ~v"2.2.3",
             ~v"2.2.2",
             ~v"2.2.1",
             ~v"2.2.0"
           ]
  end

  defp read_fixture(path) do
    File.read!(Path.join(["test", "fixtures", path]))
  end
end
