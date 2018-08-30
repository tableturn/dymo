defmodule Dymo.TaggerImplTest do
  use Dymo.DataCase, async: false
  alias Dymo.TaggerImpl
  alias Dymo.{Post, Repo}
  # doctest TaggerImpl, include: true

  @labels1 ~w(t1 t2)
  @labels2 ~w(t3 t4)
  @labels3 ~w(t1 t3)

  setup :create_labelled_posts

  test ".set_labels/2 overwrittes existing labels", %{posts: [p1, _]} do
    TaggerImpl.set_labels(p1, @labels3)

    assert @labels3 ==
             p1
             |> reload
             |> TaggerImpl.labels()
  end

  test ".add_labels/2 adds the extra labels", %{posts: [p1, p2]} do
    TaggerImpl.add_labels(p1, @labels3)

    assert Enum.uniq(@labels1 ++ @labels3) ==
             p1
             |> reload
             |> TaggerImpl.labels()

    assert Enum.uniq(@labels2) ==
             p2
             |> reload
             |> TaggerImpl.labels()
  end

  test ".remove_labels/2 removes the specified", %{posts: [p1, p2]} do
    TaggerImpl.remove_labels(p1, @labels3)

    assert Enum.uniq(@labels1 -- @labels3) ==
             p1
             |> reload
             |> TaggerImpl.labels()

    assert Enum.uniq(@labels2) ==
             p2
             |> reload
             |> TaggerImpl.labels()
  end

  test ".labels/1 returns the tagged labels", %{posts: [p1, p2]} do
    assert @labels1 ==
             p1
             |> reload
             |> TaggerImpl.labels()

    assert @labels2 ==
             p2
             |> reload
             |> TaggerImpl.labels()
  end

  test ".query_labels/2 gets tags from the given join table" do
    assert @labels1 ++ @labels2 ==
             "posts_tags"
             |> TaggerImpl.query_labels(:post_id)
             |> Repo.all()
  end

  test ".query_labels/3 gets tags from the given entity only", %{posts: [p1, p2]} do
    TaggerImpl.remove_labels(p1, "t1")

    assert ["t2"] ==
             p1
             |> TaggerImpl.query_labels("posts_tags", :post_id)
             |> Repo.all()

    assert @labels2 ==
             p2
             |> TaggerImpl.query_labels("posts_tags", :post_id)
             |> Repo.all()
  end

  describe ".query_labeled_with/4" do
    test "gets entity by label", %{posts: [%{id: id}, _]} do
      assert [%{id: ^id}] =
               Post
               |> TaggerImpl.query_labeled_with("t1", "posts_tags", :post_id)
               |> Repo.all()
    end

    test "matches all tags", %{posts: [%{id: id1}, %{id: id2}]} do
      assert [%{id: ^id1}] =
               Post
               |> TaggerImpl.query_labeled_with(@labels1, "posts_tags", :post_id)
               |> Repo.all()

      assert [%{id: ^id2}] =
               Post
               |> TaggerImpl.query_labeled_with(@labels2, "posts_tags", :post_id)
               |> Repo.all()
    end

    test "doesn't match if at least one tag differs" do
      assert [] ==
               Post
               |> TaggerImpl.query_labeled_with(@labels3, "posts_tags", :post_id)
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
          |> TaggerImpl.set_labels(&1)
          |> reload)
      )

    {:ok, posts: posts}
  end

  defp reload(%{id: id}),
    do: Repo.get!(Post, id)
end
