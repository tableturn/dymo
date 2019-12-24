defmodule Dymo.NsTest do
  use ExUnit.Case, async: true

  alias Dymo.Tag.Ns

  test ".type/0" do
    assert :string == Ns.type()
  end

  test ".cast/1" do
    assert match?({:ok, :root}, Ns.cast(nil))
    assert match?({:ok, :one}, Ns.cast(:one))
  end

  test ".load/1" do
    assert match?({:ok, :root}, Ns.load(nil))
    assert match?({:ok, :one}, Ns.load("one"))
  end

  test ".dump/1" do
    assert match?({:ok, "root"}, Ns.dump(:root))
    assert match?({:ok, "one"}, Ns.dump(:one))
  end
end
