defmodule Dymo.TaggableTest do
  use ExUnit.Case, async: true
  alias Dymo.{Taggable, Tagger}

  defmodule TestTagger do
    @behaviour Tagger

    def set_labels(s, lls), do: {s, lls}
    def add_labels(s, lls), do: {s, lls}
    def remove_labels(s, lls), do: {s, lls}
    def query_labels(jt, jk), do: {jt, jk}
    def query_labels(s, jt, jk), do: {s, jt, jk}
    def query_labeled_with(m, lls, jt, jk), do: {m, lls, jt, jk}
  end

  defmodule Dummy do
    use Taggable, implementation: TestTagger
  end

  describe "defines" do
    [
      set_labels: 2,
      add_labels: 2,
      remove_labels: 2,
      labels: 0,
      labels: 1,
      labeled_with: 1
    ]
    |> Enum.each(fn {name, arity} ->
      test "#{name}/#{arity} function" do
        Dummy
        |> Kernel.function_exported?(unquote(name), unquote(arity))
        |> assert
      end
    end)
  end

  describe "degates behaviour" do
    @join_table "dummies_tags"
    @join_id :dummy_id
    @t "hello"

    setup :taggable

    test ".set_labels/2", %{taggable: taggable} do
      assert {taggable, @t} == Dummy.set_labels(taggable, @t)
    end

    test ".add_labels/2", %{taggable: taggable} do
      assert {taggable, @t} == Dummy.add_labels(taggable, @t)
    end

    test ".remove_labels/2", %{taggable: taggable} do
      assert {taggable, @t} == Dummy.remove_labels(taggable, @t)
    end

    test ".labels/0" do
      assert {"dummies_tags", :dummy_id} == Dummy.labels()
    end

    test ".labels/1", %{taggable: taggable} do
      assert {taggable, @join_table, @join_id} == Dummy.labels(taggable)
    end

    test ".labeled_with/1" do
      assert {Dummy, @t, @join_table, :dummy_id} == Dummy.labeled_with(@t)
    end
  end

  defp taggable(_context),
    do: {:ok, taggable: %{id: :erlang.unique_integer(), tags: []}}
end
