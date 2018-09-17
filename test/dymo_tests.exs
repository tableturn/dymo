defmodule DymoTest do
  use ExUnit.Case, async: true

  test ".repo/0 returns the configured repository" do
    assert Dymo.repo() == Application.get_env(:dymo, :repo)
  end
end
