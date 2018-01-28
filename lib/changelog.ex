defmodule Changelog do
  defmodule Release do
    defstruct [:version, :date, notes: []]
  end
end
