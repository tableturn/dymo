defmodule Dymo.EndToEndTest do
  use Dymo.DataCase, async: false
  alias Dymo.{Repo, Taggable, Post}
  import Ecto.Query

  def prepare(fixtures),
    do:
      fixtures
      |> Enum.map(fn data ->
        post =
          %Post{}
          |> Post.changeset(%{title: "Hey!", body: "Bodybuilder..."})
          |> Repo.insert!()

        post
        |> Taggable.set_labels(data)

        post
      end)

  test "set_labels/{2,3} works from scratch" do
    [p1, p2, p3] =
      prepare([
        [{:a, "a1"}, "r1", {:b, "b1"}, {:b, "b2"}],
        [{:a, "a1"}, "r3", {:b, "b1"}, {:d, "d1"}],
        [{:e, "e1"}, {:e, "e2"}, {:e, "e3"}]
      ])

    # Assert on p1.
    assert ["r1"] == p1 |> labels()
    assert ["r1"] == p1 |> labels(ns: :root)
    assert ["a1"] == p1 |> labels(ns: :a)
    assert ["b1", "b2"] == p1 |> labels(ns: :b)
    assert [] == p1 |> labels(ns: :c)
    assert [] == p1 |> labels(ns: :d)
    assert [] == p1 |> labels(ns: :e)
    # Assert on p2.
    assert ["r3"] == p2 |> labels()
    assert ["r3"] == p2 |> labels(ns: :root)
    assert ["a1"] == p2 |> labels(ns: :a)
    assert ["b1"] == p2 |> labels(ns: :b)
    assert [] == p2 |> labels(ns: :c)
    assert ["d1"] == p2 |> labels(ns: :d)
    assert [] == p2 |> labels(ns: :e)
    # Assert on p3.
    assert [] == p3 |> labels()
    assert [] == p3 |> labels(ns: :root)
    assert [] == p3 |> labels(ns: :a)
    assert [] == p3 |> labels(ns: :b)
    assert [] == p3 |> labels(ns: :c)
    assert [] == p3 |> labels(ns: :d)
    assert ["e1", "e2", "e3"] == p3 |> labels(ns: :e)
  end

  test "set_labels/{2,3} overwrites tags" do
    [p1, p2, p3] =
      prepare([
        [{:a, "a1"}, "r1", {:b, "b1"}, {:b, "b2"}],
        [{:a, "a1"}, "r3", {:b, "b1"}, {:d, "d1"}],
        [{:e, "e1"}, {:e, "e2"}, {:e, "e3"}]
      ])

    p1 |> Taggable.set_labels([{:a, "a1"}, "a2", {:b, "b1"}, {:b, "b2"}], ns: :a)
    p3 |> Taggable.set_labels([{:e, "e4"}, {:e, "e5"}, {:e, "e6"}])

    # Assert on p1.
    assert ["r1"] == p1 |> labels()
    assert ["r1"] == p1 |> labels(ns: :root)
    assert ["a1", "a2"] == p1 |> labels(ns: :a)
    assert ["b1", "b2"] == p1 |> labels(ns: :b)
    assert [] == p1 |> labels(ns: :c)
    assert [] == p1 |> labels(ns: :d)
    assert [] == p1 |> labels(ns: :e)
    # Assert on p2.
    assert ["r3"] == p2 |> labels()
    assert ["r3"] == p2 |> labels(ns: :root)
    assert ["a1"] == p2 |> labels(ns: :a)
    assert ["b1"] == p2 |> labels(ns: :b)
    assert [] == p2 |> labels(ns: :c)
    assert ["d1"] == p2 |> labels(ns: :d)
    assert [] == p2 |> labels(ns: :e)
    # Assert on p3.
    assert [] == p3 |> labels()
    assert [] == p3 |> labels(ns: :root)
    assert [] == p3 |> labels(ns: :a)
    assert [] == p3 |> labels(ns: :b)
    assert [] == p3 |> labels(ns: :c)
    assert [] == p3 |> labels(ns: :d)
    assert ["e4", "e5", "e6"] == p3 |> labels(ns: :e)
  end

  test "add_labels/{2,3} adds labels on top" do
    [p1, p2, p3] =
      prepare([
        [{:a, "a1"}, {:a, "a2"}, "r1", {:b, "b1"}, {:b, "b2"}],
        [{:a, "a1"}, "r3", {:b, "b1"}, {:d, "d1"}],
        [{:e, "e4"}, {:e, "e5"}, {:e, "e6"}]
      ])

    p1
    |> Taggable.add_labels("r2")
    |> Taggable.add_labels([{:a, "a3"}, "c1", {:b, "b3"}, {:b, "b4"}], ns: :c)

    p2 |> Taggable.add_labels([{:d, "d2"}, {:d, "d3"}])
    # Assert on p1.
    assert ["r1", "r2"] == p1 |> labels()
    assert ["r1", "r2"] == p1 |> labels(ns: :root)
    assert ["a1", "a2", "a3"] == p1 |> labels(ns: :a)
    assert ["b1", "b2", "b3", "b4"] == p1 |> labels(ns: :b)
    assert ["c1"] == p1 |> labels(ns: :c)
    assert [] == p1 |> labels(ns: :d)
    assert [] == p1 |> labels(ns: :e)
    # Assert on p2.
    assert ["r3"] == p2 |> labels()
    assert ["r3"] == p2 |> labels(ns: :root)
    assert ["a1"] == p2 |> labels(ns: :a)
    assert ["b1"] == p2 |> labels(ns: :b)
    assert [] == p2 |> labels(ns: :c)
    assert ["d1", "d2", "d3"] == p2 |> labels(ns: :d)
    assert [] == p2 |> labels(ns: :e)
    # Assert on p3.
    assert [] == p3 |> labels()
    assert [] == p3 |> labels(ns: :root)
    assert [] == p3 |> labels(ns: :a)
    assert [] == p3 |> labels(ns: :b)
    assert [] == p3 |> labels(ns: :c)
    assert [] == p3 |> labels(ns: :d)
    assert ["e4", "e5", "e6"] == p3 |> labels(ns: :e)
  end

  test "remove_labels/{2,3} doesn't remove un-necessary labels" do
    [p1, p2, p3] =
      prepare([
        [{:a, "a1"}, {:a, "a2"}, {:a, "a3"}, "r1", "r2", {:b, "b1"}, {:b, "b3"}, {:c, "c1"}],
        [{:a, "a1"}, "r3", {:b, "b1"}, {:d, "d1"}, {:d, "d2"}, {:d, "d3"}],
        [{:e, "e4"}, {:e, "e5"}, {:e, "e6"}]
      ])

    p1
    |> Taggable.remove_labels("a2")
    |> Taggable.remove_labels({:b, "a2"})
    |> Taggable.remove_labels("a2", ns: :c)

    # Assert on p1.
    assert ["r1", "r2"] == p1 |> labels()
    assert ["r1", "r2"] == p1 |> labels(ns: :root)
    assert ["a1", "a2", "a3"] == p1 |> labels(ns: :a)
    assert ["b1", "b3"] == p1 |> labels(ns: :b)
    assert ["c1"] == p1 |> labels(ns: :c)
    assert [] == p1 |> labels(ns: :d)
    assert [] == p1 |> labels(ns: :e)
    # Assert on p2.
    assert ["r3"] == p2 |> labels()
    assert ["r3"] == p2 |> labels(ns: :root)
    assert ["a1"] == p2 |> labels(ns: :a)
    assert ["b1"] == p2 |> labels(ns: :b)
    assert [] == p2 |> labels(ns: :c)
    assert ["d1", "d2", "d3"] == p2 |> labels(ns: :d)
    assert [] == p2 |> labels(ns: :e)
    # Assert on p3.
    assert [] == p3 |> labels()
    assert [] == p3 |> labels(ns: :root)
    assert [] == p3 |> labels(ns: :a)
    assert [] == p3 |> labels(ns: :b)
    assert [] == p3 |> labels(ns: :c)
    assert [] == p3 |> labels(ns: :d)
    assert ["e4", "e5", "e6"] == p3 |> labels(ns: :e)
  end

  test "remove_labels/{2,3} removes labels" do
    [p1, p2, p3] =
      prepare([
        [{:a, "a1"}, {:a, "a2"}, {:a, "a3"}, "r1", "r2", {:b, "b1"}, {:b, "b3"}, {:c, "c1"}],
        [{:a, "a1"}, "r3", {:b, "b1"}, {:d, "d1"}, {:d, "d2"}, {:d, "d3"}],
        [{:e, "e4"}, {:e, "e5"}, {:e, "e6"}]
      ])

    p1
    |> Taggable.remove_labels("a2", ns: :a)
    |> Taggable.remove_labels({:b, "b1"})
    |> Taggable.remove_labels("r1")

    p2
    |> Taggable.remove_labels([{:a, "a1"}, {:a, "a2"}])
    |> Taggable.remove_labels(["d2", "d3"], ns: :d)

    p2 |> Taggable.remove_labels("d2", ns: :d)
    # Assert on p1.
    assert ["r2"] == p1 |> labels()
    assert ["r2"] == p1 |> labels(ns: :root)
    assert ["a1", "a3"] == p1 |> labels(ns: :a)
    assert ["b3"] == p1 |> labels(ns: :b)
    assert ["c1"] == p1 |> labels(ns: :c)
    assert [] == p1 |> labels(ns: :d)
    assert [] == p1 |> labels(ns: :e)
    # Assert on p2.
    assert ["r3"] == p2 |> labels()
    assert ["r3"] == p2 |> labels(ns: :root)
    assert [] == p2 |> labels(ns: :a)
    assert ["b1"] == p2 |> labels(ns: :b)
    assert ["d1"] == p2 |> labels(ns: :d)
    assert [] == p2 |> labels(ns: :e)
    # Assert on p3.
    assert [] == p3 |> labels()
    assert [] == p3 |> labels(ns: :root)
    assert [] == p3 |> labels(ns: :a)
    assert [] == p3 |> labels(ns: :b)
    assert [] == p3 |> labels(ns: :c)
    assert [] == p3 |> labels(ns: :d)
    assert ["e4", "e5", "e6"] == p3 |> labels(ns: :e)
  end

  test "all_labels/{1, 2}" do
    prepare([
      [{:a, "a1"}, {:a, "a2"}, {:a, "a3"}, "r1", "r2", {:b, "b1"}, {:b, "b3"}, {:c, "c1"}],
      [{:a, "a1"}, "r3", {:b, "b1"}, {:d, "d1"}, {:d, "d2"}, {:d, "d3"}],
      [{:e, "e4"}, {:e, "e5"}, {:e, "e6"}]
    ])

    # Reads all tags in root namespace...
    assert ["r1", "r2", "r3"] == all_labels()
    assert ["r1", "r2", "r3"] == all_labels(ns: :root)
    # Read all tags in various namespaces.
    assert ["a1", "a2", "a3"] == all_labels(ns: :a)
    assert ["b1", "b3"] == all_labels(ns: :b)
    assert ["c1"] == all_labels(ns: :c)
    assert ["d1", "d2", "d3"] == all_labels(ns: :d)
    assert ["e4", "e5", "e6"] == all_labels(ns: :e)
  end

  test "labeled_with/{2,3}" do
    [p1, p2, p3] =
      prepare([
        [{:a, "a1"}, {:a, "a2"}, {:a, "a3"}, "r1", "r2", {:b, "b1"}, {:b, "b3"}, {:c, "c1"}],
        [{:a, "a1"}, "r3", {:b, "b1"}, {:d, "d1"}, {:d, "d2"}, {:d, "d3"}],
        [{:e, "e4"}, {:e, "e5"}, {:e, "e6"}]
      ])

    # Get posts tagged with certain tags.
    assert [p1.id, p2.id] == {:a, "a1"} |> labeled_with()
    assert [p1.id, p2.id] == ["r2", "r3"] |> labeled_with()
    assert [p1.id] == [{:a, "a3"}, {:b, "b3"}, {:b, "b4"}] |> labeled_with()
    assert [p1.id, p2.id] == {:b, "b1"} |> labeled_with()
    assert [p3.id] == {:e, "e4"} |> labeled_with()
  end

  defp all_labels(opts \\ []),
    do: Post |> Taggable.all_labels(opts) |> Repo.all()

  defp labeled_with(labels),
    do:
      Post
      |> Taggable.labeled_with(labels)
      |> select([t], t.id)
      |> order_by([t], t.id)
      |> Repo.all()

  defp labels(taggable, opts \\ []),
    do:
      taggable
      |> Taggable.labels(opts)
      |> Repo.all()
      |> Enum.sort()
end
