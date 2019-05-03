defmodule Dymo.NsTest do
  use ExUnit.Case, async: true

  alias Dymo.Tag.Ns

  test ".type/0" do
    assert :string == Ns.type()
  end

  test ".cast/1" do
    assert {:ok, []} == Ns.cast(nil)
    assert {:ok, []} == Ns.cast([])
    assert {:ok, []} == Ns.cast([])
    assert {:ok, [:one]} == Ns.cast(:one)
    assert {:ok, [:one]} == Ns.cast([:one])
    assert {:ok, [:one, :two]} == Ns.cast([:one, :two])

    assert :error == Ns.cast([:one, "two"])
  end

  test ".load/1" do
    assert {:ok, []} == Ns.load("")
    assert {:ok, []} == Ns.load(":")
    assert {:ok, [:one]} == Ns.load("one")
    assert {:ok, [:one, :two]} == Ns.load("one:two")
  end

  test ".dump/1" do
    assert {:ok, ":"} == Ns.dump([])
    assert {:ok, "one"} == Ns.dump([:one])
    assert {:ok, "one:two"} == Ns.dump([:one, :two])
  end
end
