defmodule Dymo.TaggableTest do
  use ExUnit.Case, async: true
  alias Dymo.{Taggable, Tagger}

  defmodule TestTagger do
    @behaviour Tagger

    def set_labels(s, _ns \\ nil, lls), do: {s, lls}
    def add_labels(s, _ns \\ nil, lls), do: {s, lls}
    def remove_labels(s, _ns \\ nil, lls), do: {s, lls}
    def query_all_labels(jt, jk, _ns \\ nil), do: {jt, jk}
    def query_labels(s, jt, jk, _ns \\ nil), do: {s, jt, jk}
    def query_labeled_with(m, tags, jt, jk), do: {m, tags, jt, jk}
  end

  defmodule Dummy do
    use Ecto.Schema
    use Taggable, implementation: TestTagger

    schema "dummies" do
      tags()
    end
  end

  describe "defines" do
    [
      all_labels: 0,
      all_labels: 1,
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
      assert {taggable, @t} == Taggable.set_labels(taggable, @t)
    end

    test ".add_labels/2", %{taggable: taggable} do
      assert {taggable, @t} == Taggable.add_labels(taggable, @t)
    end

    test ".remove_labels/2", %{taggable: taggable} do
      assert {taggable, @t} == Taggable.remove_labels(taggable, @t)
    end

    test ".all_labels/1" do
      assert {"dummies_tags", :dummy_id} == Taggable.all_labels(Dummy)
    end

    test ".labels/1", %{taggable: taggable} do
      assert {taggable, @join_table, @join_id} == Taggable.labels(taggable)
    end

    test ".labeled_with/2" do
      assert {Dummy, @t, @join_table, :dummy_id} == Taggable.labeled_with(Dummy, @t)
    end
  end

  defp taggable(_context),
    do: {:ok, taggable: %Dummy{id: :erlang.unique_integer(), tags: []}}
end
