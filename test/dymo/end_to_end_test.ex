defmodule Dymo.EndToEndTest do
  use Dymo.DataCase, async: false
  alias Dymo.{Repo, Taggable, Post}
  import Ecto.Query

  setup do
    posts =
      1..5
      |> Enum.map(fn i ->
        %Post{}
        |> Post.changeset(%{title: "Hey #{i}", body: "Hoy #{i}!"})
        |> Repo.insert!()
      end)

    %{posts: posts}
  end

  test "can read, add and remove end-to-end", %{posts: [p1, p2, p3, p4, p5]} do
    # Starts without any labels...
    assert p1 |> taggable_labels() |> Enum.empty?()

    # Sets labels...
    p1 |> Taggable.set_labels([{:a, "a1"}, "r1", {:b, "b1"}, {:b, "b2"}])
    p2 |> Taggable.set_labels([{:a, "a1"}, "r3", {:b, "b1"}, {:d, "d1"}])
    # Assert on p1.
    assert ["r1"] == p1 |> taggable_labels()
    assert ["r1"] == p1 |> taggable_labels(ns: :root)
    assert ["a1"] == p1 |> taggable_labels(ns: :a)
    assert ["b1", "b2"] == p1 |> taggable_labels(ns: :b)
    # Assert on p2.
    assert ["r3"] == p2 |> taggable_labels()
    assert ["r3"] == p2 |> taggable_labels(ns: :root)
    assert ["a1"] == p2 |> taggable_labels(ns: :a)
    assert ["b1"] == p2 |> taggable_labels(ns: :b)
    assert ["d1"] == p2 |> taggable_labels(ns: :d)

    # Sets labels using the optional namespace...
    p1 |> Taggable.set_labels([{:a, "a1"}, "a2", {:b, "b1"}, {:b, "b2"}], ns: :a)
    # Assert on p1.
    assert ["r1"] == p1 |> taggable_labels()
    assert ["r1"] == p1 |> taggable_labels(ns: :root)
    assert ["a1", "a2"] == p1 |> taggable_labels(ns: :a)
    assert ["b1", "b2"] == p1 |> taggable_labels(ns: :b)
    # Assert on p2.
    assert ["r3"] == p2 |> taggable_labels()
    assert ["r3"] == p2 |> taggable_labels(ns: :root)
    assert ["a1"] == p2 |> taggable_labels(ns: :a)
    assert ["b1"] == p2 |> taggable_labels(ns: :b)
    assert ["d1"] == p2 |> taggable_labels(ns: :d)

    # Adds labels...
    p1 |> Taggable.add_labels("r2")
    p1 |> Taggable.add_labels([{:a, "a3"}, "c1", {:b, "b3"}, {:b, "b4"}], ns: :c)
    p2 |> Taggable.add_labels([{:d, "d2"}, {:d, "d3"}])
    # Assert on p1.
    assert ["r1", "r2"] == p1 |> taggable_labels()
    assert ["r1", "r2"] == p1 |> taggable_labels(ns: :root)
    assert ["a1", "a2", "a3"] == p1 |> taggable_labels(ns: :a)
    assert ["b1", "b2", "b3", "b4"] == p1 |> taggable_labels(ns: :b)
    assert ["c1"] == p1 |> taggable_labels(ns: :c)
    # Assert on p2.
    assert ["r3"] == p2 |> taggable_labels()
    assert ["r3"] == p2 |> taggable_labels(ns: :root)
    assert ["a1"] == p2 |> taggable_labels(ns: :a)
    assert ["b1"] == p2 |> taggable_labels(ns: :b)
    assert ["d1", "d2", "d3"] == p2 |> taggable_labels(ns: :d)

    # Removes no labels...
    p1 |> Taggable.remove_labels("a2")
    p1 |> Taggable.remove_labels({:b, "a2"})
    p1 |> Taggable.remove_labels("a2", ns: :c)
    # Assert on p1.
    assert ["r1", "r2"] == p1 |> taggable_labels()
    assert ["r1", "r2"] == p1 |> taggable_labels(ns: :root)
    assert ["a1", "a2", "a3"] == p1 |> taggable_labels(ns: :a)
    assert ["b1", "b2", "b3", "b4"] == p1 |> taggable_labels(ns: :b)
    assert ["c1"] == p1 |> taggable_labels(ns: :c)
    # Assert on p2.
    assert ["r3"] == p2 |> taggable_labels()
    assert ["r3"] == p2 |> taggable_labels(ns: :root)
    assert ["a1"] == p2 |> taggable_labels(ns: :a)
    assert ["b1"] == p2 |> taggable_labels(ns: :b)
    assert ["d1", "d2", "d3"] == p2 |> taggable_labels(ns: :d)

    # Removes labels...
    p1 |> Taggable.remove_labels("a2", ns: :a)
    p1 |> Taggable.remove_labels({:b, "b1"})
    p1 |> Taggable.remove_labels("r1")
    p2 |> Taggable.remove_labels("d2", ns: :d)
    # Assert on p1.
    assert ["r2"] == p1 |> taggable_labels()
    assert ["r2"] == p1 |> taggable_labels(ns: :root)
    assert ["a1", "a3"] == p1 |> taggable_labels(ns: :a)
    assert ["b2", "b3", "b4"] == p1 |> taggable_labels(ns: :b)
    assert ["c1"] == p1 |> taggable_labels(ns: :c)
    # Assert on p2.
    assert ["r3"] == p2 |> taggable_labels()
    assert ["r3"] == p2 |> taggable_labels(ns: :root)
    assert ["a1"] == p2 |> taggable_labels(ns: :a)
    assert ["b1"] == p2 |> taggable_labels(ns: :b)
    assert ["d1", "d3"] == p2 |> taggable_labels(ns: :d)

    # Reads all tags in root namespace...
    assert ["r3", "r2"] == Post |> Taggable.all_labels() |> Repo.all()
    assert ["r3", "r2"] == Post |> Taggable.all_labels(ns: :root) |> Repo.all()
    # Read all tags in various namespaces.
    assert ["a1", "a3"] == Post |> Taggable.all_labels(ns: :a) |> Repo.all()
    assert ["b1", "b2", "b3", "b4"] == Post |> Taggable.all_labels(ns: :b) |> Repo.all()
    assert ["c1"] == Post |> Taggable.all_labels(ns: :c) |> Repo.all()
    assert ["d1", "d3"] == Post |> Taggable.all_labels(ns: :d) |> Repo.all()

    # Get posts tagged with certain tags.
    assert [p1.id, p2.id] ==
             Post
             |> Taggable.labeled_with({:a, "a1"})
             |> select([t], t.id)
             |> order_by([t], t.id)
             |> Repo.all()

    assert [p1.id, p2.id] ==
             Post
             |> Taggable.labeled_with(["r2", "r3"])
             |> select([t], t.id)
             |> order_by([t], t.id)
             |> Repo.all()

    assert [p1.id] ==
             Post
             |> Taggable.labeled_with([{:a, "a3"}, {:b, "b3"}, {:b, "b4"}])
             |> select([t], t.id)
             |> order_by([t], t.id)
             |> Repo.all()

    assert [p2.id] ==
             Post
             |> Taggable.labeled_with({:b, "b1"})
             |> select([t], t.id)
             |> order_by([t], t.id)
             |> Repo.all()
  end

  defp tuppleify(labels, ns) when is_list(labels),
    do: labels |> Enum.map(&tuppleify(&1, ns))

  defp tuppleify(label, ns) when is_binary(label),
    do: {ns, label}

  defp taggable_labels(taggable, opts \\ []),
    do:
      taggable
      |> Taggable.labels(opts)
      |> Repo.all()
      |> Enum.sort()
end
