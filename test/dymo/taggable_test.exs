defmodule Dymo.TaggableTest do
  use ExUnit.Case, async: true
  alias Dymo.{Taggable, Tagger}

  defmodule TestTagger do
    @behaviour Tagger

    def labels(s, jt, jk, opts \\ []), do: {s, jt, jk, opts}
    def set_labels(s, lls, opts \\ []), do: {s, lls, opts}
    def add_labels(s, lls, opts \\ []), do: {s, lls, opts}
    def remove_labels(s, lls, opts \\ []), do: {s, lls, opts}
    def all_labels(jt, jk, opts \\ []), do: {jt, jk, opts}
    def labeled_with(m, tags, jt, jk, opts \\ []), do: {m, tags, jt, jk, opts}
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

    @no_opts []
    @opts [foo: :baz]

    setup :taggable

    test ".labels/{3,4}", %{taggable: taggable} do
      assert {taggable, @join_table, @join_id, @no_opts} ==
               taggable |> Taggable.labels()

      assert {taggable, @join_table, @join_id, @opts} ==
               taggable |> Taggable.labels(@opts)
    end

    test ".set_labels/{2,3}", %{taggable: taggable} do
      assert {taggable, @label, @no_opts} ==
               taggable |> Taggable.set_labels(@label)

      assert {taggable, @label, @opts} ==
               taggable |> Taggable.set_labels(@label, @opts)
    end

    test ".add_labels/{2,3}", %{taggable: taggable} do
      assert {taggable, @label, @no_opts} ==
               taggable |> Taggable.add_labels(@label)

      assert {taggable, @label, @no_opts} ==
               taggable |> Taggable.add_labels(@label)
    end

    test ".remove_labels/{2,3}", %{taggable: taggable} do
      assert {taggable, @label, @no_opts} ==
               taggable |> Taggable.remove_labels(@label)

      assert {taggable, @label, @opts} ==
               taggable |> Taggable.remove_labels(@label, @opts)
    end

    test ".all_labels/{2,3}" do
      assert {"dummies_tags", :dummy_id, @no_opts} ==
               Dummy |> Taggable.all_labels()
    end

    test ".labels/{1,2}", %{taggable: taggable} do
      assert {taggable, @join_table, @join_id, @no_opts} ==
               taggable |> Taggable.labels()
    end

    test ".labeled_with/{4,5}" do
      assert {Dummy, @label, @join_table, :dummy_id, @no_opts} ==
               Dummy |> Taggable.labeled_with(@label)

      assert {Dummy, @label, @join_table, :dummy_id, @opts} ==
               Dummy |> Taggable.labeled_with(@label, @opts)
    end
  end

  defp taggable(_context),
    do: {:ok, taggable: %Dummy{id: :erlang.unique_integer(), tags: @no_opts}}
end
