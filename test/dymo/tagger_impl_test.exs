defmodule Dymo.TaggerImplTest do
  use Dymo.DataCase, async: false
  alias Dymo.TaggerImpl
  alias Dymo.{Post, Repo}
  # doctest TaggerImpl, include: true

  @labels1 ~w(t11 t12)
  @labels2 ~w(t21 t22)
  @labels3 ~w(t31 t32)
  @labels4 ~w(t41 t42)
  @nonexistent_labels ~w(tn1 tn2)

  setup :create_labelled_posts

  describe ".set_labels/3" do
    test "can overwrites existing labels", %{posts: [p1, _]} do
      p1 |> TaggerImpl.set_labels(nil, @labels3)

      assert @labels3 ==
               p1
               |> reload
               |> TaggerImpl.labels(nil)
    end

    test "can overwrite existing labels with the same namespace", %{posts: [p1, _]} do
      TaggerImpl.set_labels(p1, :ns1, @labels4)

      p1 = reload(p1)

      assert @labels1 == TaggerImpl.labels(p1, nil)
      assert @labels4 == TaggerImpl.labels(p1, :ns1)
    end

    test "can be prevented from creating new tags", %{posts: [p1, _]} do
      p1 |> TaggerImpl.set_labels(nil, @nonexistent_labels, create_missing: false)
      p1 = reload(p1)
      assert [] == p1 |> TaggerImpl.labels(nil)
    end
  end

  describe ".add_labels/4" do
    test "adds the extra labels", %{posts: [p1, p2]} do
      p1 |> TaggerImpl.add_labels(:root, @labels3)

      assert Enum.uniq(@labels1 ++ @labels3) ==
               p1
               |> reload
               |> TaggerImpl.labels(nil)

      assert @labels2 ==
               p2
               |> reload
               |> TaggerImpl.labels(nil)
    end

    test "adds the extra labels in the given namespace", %{posts: [p1, _]} do
      p1 |> TaggerImpl.add_labels(nil, @labels3)
      p1 |> TaggerImpl.add_labels(:ns1, @labels3)

      p1 = reload(p1)

      assert Enum.uniq(@labels1 ++ @labels3) == p1 |> TaggerImpl.labels(nil)
      assert @labels3 == TaggerImpl.labels(p1, :ns1)
    end
  end

  describe ".remove_labels/3" do
    test "removes the specified labels", %{posts: [p1, p2]} do
      p1 |> TaggerImpl.remove_labels(nil, @labels3)

      assert Enum.uniq(@labels1 -- @labels3) ==
               p1
               |> reload
               |> TaggerImpl.labels(nil)

      assert @labels2 ==
               p2
               |> reload
               |> TaggerImpl.labels(nil)
    end
  end

  describe ".labels/2" do
    test "returns the tagged labels", %{posts: [p1, p2]} do
      assert @labels1 ==
               p1
               |> reload
               |> TaggerImpl.labels(nil)

      assert @labels2 ==
               p2
               |> reload
               |> TaggerImpl.labels(nil)
    end

    test "returns the tagged labels in a given namespace", %{posts: [p1, _]} do
      p1 |> TaggerImpl.set_labels(:ns1, @labels3)

      assert @labels3 ==
               p1
               |> reload
               |> TaggerImpl.labels(:ns1)
    end
  end

  describe ".query_all_labels/3" do
    test "gets tags from the given join table" do
      assert @labels1 ++ @labels2 ==
               "taggings"
               |> TaggerImpl.query_all_labels(:post_id, nil)
               |> Repo.all()
    end
  end

  describe ".query_labels/3" do
    test "gets tags from the given entity", %{posts: [p1, p2]} do
      p1 |> TaggerImpl.remove_labels(nil, "t11")

      assert ["t12"] ==
               p1
               |> TaggerImpl.query_labels("taggings", :post_id, nil)
               |> Repo.all()

      assert @labels2 ==
               p2
               |> TaggerImpl.query_labels("taggings", :post_id, nil)
               |> Repo.all()
    end
  end

  describe ".query_labeled_with/4" do
    test "gets entity by label", %{posts: [%{id: id}, _]} do
      assert [%{id: ^id}] =
               Post
               |> TaggerImpl.query_labeled_with("t11", "taggings", :post_id)
               |> Repo.all()
    end

    test "matches all tags", %{posts: [%{id: id1}, %{id: id2}]} do
      assert [%{id: ^id1}] =
               Post
               |> TaggerImpl.query_labeled_with(@labels1, "taggings", :post_id)
               |> Repo.all()

      assert [%{id: ^id2}] =
               Post
               |> TaggerImpl.query_labeled_with(@labels2, "taggings", :post_id)
               |> Repo.all()
    end

    test "doesn't match if at least one tag differs" do
      assert [] ==
               Post
               |> TaggerImpl.query_labeled_with(@labels3, "taggings", :post_id)
               |> Repo.all()
    end
  end

  defp create_labelled_posts(_) do
    posts =
      [@labels1, @labels2]
      |> Enum.map(
        &(%Post{}
          |> Post.changeset(%{title: "Hello #{:erlang.unique_integer()}!", body: "Bodybuilder."})
          |> Repo.insert!()
          |> TaggerImpl.set_labels(nil, &1)
          |> reload)
      )

    {:ok, posts: posts}
  end

  defp reload(%{id: id}),
    do: Repo.get!(Post, id)
end
