defmodule Dymo.TaggableTest do
  use ExUnit.Case, async: true
  alias Dymo.{Taggable, Tagger}

  defmodule TestTagger do
    @behaviour Tagger

    def set_labels(s, _ns, lls, _ \\ []), do: {s, lls}
    def add_labels(s, _ns, lls, _ \\ []), do: {s, lls}
    def remove_labels(s, _ns, lls), do: {s, lls}
    def query_all_labels(jt, jk, _ns), do: {jt, jk}
    def query_labels(s, jt, jk, _ns), do: {s, jt, jk}
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

    test ".add_labels/3", %{taggable: taggable} do
      assert {taggable, @t} == taggable |> Taggable.add_labels(nil, @t)
    end

    test ".set_labels/3", %{taggable: taggable} do
      assert {taggable, @t} == taggable |> Taggable.set_labels(nil, @t)
    end

    test ".remove_labels/2", %{taggable: taggable} do
      assert {taggable, @t} == taggable |> Taggable.remove_labels(nil, @t)
    end

    test ".all_labels/2" do
      assert {"dummies_tags", :dummy_id} == Dummy |> Taggable.all_labels(nil)
    end

    test ".labels/1", %{taggable: taggable} do
      assert {taggable, @join_table, @join_id} == taggable |> Taggable.labels(nil)
    end

    test ".labeled_with/2" do
      assert {Dummy, @t, @join_table, :dummy_id} == Dummy |> Taggable.labeled_with(@t)
    end
  end

  defp taggable(_context),
    do: {:ok, taggable: %Dummy{id: :erlang.unique_integer(), tags: []}}
end
