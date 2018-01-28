defmodule Mix.Tasks.Changelog do
  use Mix.Task
  @moduledoc false

  def run(args) do
    Changelog.CLI.main(args)
  end
end
