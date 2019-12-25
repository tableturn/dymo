defmodule Dymo.TaggerImplTest do
  use Dymo.DataCase, async: false
  alias Dymo.TaggerImpl
  alias Dymo.{Post, Repo}

  doctest TaggerImpl, include: true

  @labels1 ~w(t11 t12)
  @labels2 ~w(t21 t22)
  @labels3 ~w(t31 t32)
  @labels4 ~w(t41 t42)
  @nonexistent_labels ~w(tn1 tn2)

  setup :create_labelled_posts

  describe ".set_labels/3" do
    test "can overwrites existing labels", %{posts: [p1, _]} do
      p1 |> TaggerImpl.set_labels(@labels3)

      assert @labels3 ==
               p1
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()
    end

    test "can overwrite existing labels with the same namespace", %{posts: [p1, _]} do
      p1 |> TaggerImpl.set_labels(Enum.map(@labels4, &{:ns1, &1}))

      assert @labels1 ==
               p1
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()
               |> Enum.sort()

      assert @labels4 ==
               p1
               |> TaggerImpl.labels("taggings", :post_id, ns: :ns1)
               |> Repo.all()
               |> Enum.sort()
    end

    test "can be prevented from creating new tags", %{posts: [p1, _]} do
      p1 |> TaggerImpl.set_labels(@nonexistent_labels, create_missing: false)

      assert p1
             |> TaggerImpl.labels("taggings", :post_id)
             |> Repo.all()
             |> Enum.empty?()
    end
  end

  describe ".add_labels/{2,3}" do
    test "adds the extra labels", %{posts: [p1, p2]} do
      p1 |> TaggerImpl.add_labels(@labels3)

      assert (@labels1 ++ @labels3) |> Enum.uniq() |> Enum.sort() ==
               p1
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()
               |> Enum.sort()

      assert @labels2 ==
               p2
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()
               |> Enum.sort()
    end

    test "adds the extra labels in the given namespace", %{posts: [p1, _]} do
      p1 |> TaggerImpl.add_labels(@labels3)
      p1 |> TaggerImpl.add_labels(Enum.map(@labels3, &{:ns1, &1}))

      assert (@labels1 ++ @labels3) |> Enum.uniq() |> Enum.sort() ==
               p1
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()
               |> Enum.sort()

      assert @labels3 ==
               p1
               |> TaggerImpl.labels("taggings", :post_id, ns: :ns1)
               |> Repo.all()
               |> Enum.sort()
    end
  end

  describe ".remove_labels/{2,3}" do
    test "removes the specified labels", %{posts: [p1, p2]} do
      p1 |> TaggerImpl.remove_labels(@labels3)

      assert Enum.uniq(@labels1 -- @labels3) ==
               p1
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()

      assert @labels2 ==
               p2
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()
    end
  end

  describe ".labels/4" do
    test "returns the tagged labels", %{posts: [p1, p2]} do
      assert @labels1 ==
               p1
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()

      assert @labels2 ==
               p2
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()
    end

    test "returns the tagged labels in a given namespace", %{posts: [p1, _]} do
      p1 |> TaggerImpl.set_labels(Enum.map(@labels3, &{:ns1, &1}))

      assert @labels3 ==
               p1
               |> TaggerImpl.labels("taggings", :post_id, ns: :ns1)
               |> Repo.all()
    end
  end

  describe ".all_labels/{2,3}" do
    test "gets tags from the given join table" do
      assert @labels1 ++ @labels2 ==
               "taggings"
               |> TaggerImpl.all_labels(:post_id)
               |> Repo.all()
    end
  end

  describe ".labels/3" do
    test "gets tags from the given entity", %{posts: [p1, p2]} do
      p1 |> TaggerImpl.remove_labels("t11")

      assert ["t12"] ==
               p1
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()

      assert @labels2 ==
               p2
               |> TaggerImpl.labels("taggings", :post_id)
               |> Repo.all()
    end
  end

  describe ".labeled_with/4" do
    test "gets entity by label", %{posts: [%{id: id}, _]} do
      assert [%{id: ^id}] =
               Post
               |> TaggerImpl.labeled_with("t11", "taggings", :post_id)
               |> Repo.all()
    end

    test "matches all tags", %{posts: [%{id: id1}, %{id: id2}]} do
      assert [%{id: ^id1}] =
               Post
               |> TaggerImpl.labeled_with(@labels1, "taggings", :post_id)
               |> Repo.all()

      assert [%{id: ^id2}] =
               Post
               |> TaggerImpl.labeled_with(@labels2, "taggings", :post_id)
               |> Repo.all()
    end

    test "doesn't match if at least one tag differs" do
      assert [] ==
               Post
               |> TaggerImpl.labeled_with(@labels3, "taggings", :post_id)
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
          |> TaggerImpl.set_labels(&1))
      )

    {:ok, posts: posts}
  end
end
