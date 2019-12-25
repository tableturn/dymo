defmodule Dymo.TaggableTest do
  use ExUnit.Case, async: true
  alias Dymo.{Taggable, Tagger}

  defmodule TestTagger do
    @behaviour Tagger

    def add_labels(s, lls, opts \\ []), do: {s, lls, opts}
    def set_labels(s, lls, opts \\ []), do: {s, lls, opts}
    def remove_labels(s, lls, opts \\ []), do: {s, lls, opts}
    def all_labels(jt, jk, opts \\ []), do: {jt, jk, opts}
    def labels(s, jt, jk, opts \\ []), do: {s, jt, jk, opts}
    def labeled_with(m, tags, jt, jk), do: {m, tags, jt, jk}
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
    @label {:hey, "Hoy"}

    setup :taggable

    test ".add_labels/{2,3}", %{taggable: taggable} do
      assert {taggable, @label, []} ==
               taggable |> Taggable.add_labels(@label)

      assert {taggable, {:baz, @label}, []} ==
               taggable |> Taggable.add_labels({:baz, @label})
    end

    test ".set_labels/{3,4}", %{taggable: taggable} do
      assert {taggable, @label, []} ==
               taggable |> Taggable.set_labels(@label)

      assert {taggable, {:ns1, @label}, [foo: :baz]} ==
               taggable |> Taggable.set_labels({:ns1, @label}, foo: :baz)
    end

    test ".remove_labels/{2,3}", %{taggable: taggable} do
      assert {taggable, @label, []} == taggable |> Taggable.remove_labels(@label)
    end

    test ".all_labels/{2,3}" do
      assert {"dummies_tags", :dummy_id, []} == Dummy |> Taggable.all_labels()
    end

    test ".labels/{1,2}", %{taggable: taggable} do
      assert {taggable, @join_table, @join_id, []} == taggable |> Taggable.labels()
    end

    test ".labeled_with/2" do
      assert {Dummy, "Hey", @join_table, :dummy_id} == Dummy |> Taggable.labeled_with("Hey")
    end
  end

  defp taggable(_context),
    do: {:ok, taggable: %Dummy{id: :erlang.unique_integer(), tags: []}}
end
