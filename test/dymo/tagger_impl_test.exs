defmodule Dymo.TaggerImplTest do
  use Dymo.DataCase, async: true
  alias Dymo.TaggerImpl
  alias Dymo.{Post, Repo}

  @labels ~w(one two)
  @other_labels ~w(one three)

  setup :create_labelled_post

  test ".set_labels/2 overwrittes existing labels", %{post: post} do
    TaggerImpl.set_labels(post, @other_labels)

    assert @other_labels ==
             post
             |> reload
             |> TaggerImpl.labels()
  end

  test ".add_labels/2 adds the extra labels", %{post: post} do
    TaggerImpl.add_labels(post, @other_labels)

    assert Enum.uniq(@labels ++ @other_labels) ==
             post
             |> reload
             |> TaggerImpl.labels()
  end

  test ".remove_labels/2 removes the specified", %{post: post} do
    TaggerImpl.remove_labels(post, @other_labels)

    assert Enum.uniq(@labels -- @other_labels) ==
             post
             |> reload
             |> TaggerImpl.labels()
  end

  test ".labels/1 returns the tagged labels", %{post: post} do
    assert @labels ==
             post
             |> reload
             |> TaggerImpl.labels()
  end

  test ".query_labels/1a gets all tags" do
    assert @labels ==
             Post
             |> TaggerImpl.query_labels()
             |> Repo.all()
  end

  test ".query_labels/1b gets tags from the given entity", %{post: post} do
    assert @labels ==
             post
             |> reload
             |> TaggerImpl.query_labels()
             |> Repo.all()
  end

  test ".query_labels/3 gets tags from the given entity", %{post: post} do
    TaggerImpl.remove_labels(post, "one")

    assert ["two"] ==
             post
             |> TaggerImpl.query_labels("posts_tags", :post_id)
             |> Repo.all()
  end

  describe ".query_labeled_with/2/4" do
    test "gets entity by label", %{post: %{id: id}} do
      assert [%{id: ^id}] =
               Post
               |> TaggerImpl.query_labeled_with("one")
               |> Repo.all()

      assert [%{id: ^id}] =
               Post
               |> TaggerImpl.query_labeled_with("one", "posts_tags", :post_id)
               |> Repo.all()
    end

    test "matches all tags", %{post: %{id: id}} do
      assert [%{id: ^id}] =
               Post
               |> TaggerImpl.query_labeled_with(@labels)
               |> Repo.all()

      assert [%{id: ^id}] =
               Post
               |> TaggerImpl.query_labeled_with(@labels, "posts_tags", :post_id)
               |> Repo.all()
    end

    test "doesn't match if at least one tag differs" do
      assert [] ==
               Post
               |> TaggerImpl.query_labeled_with(@other_labels)
               |> Repo.all()

      assert [] ==
               Post
               |> TaggerImpl.query_labeled_with(@other_labels, "posts_tags", :post_id)
               |> Repo.all()
    end
  end

  defp create_labelled_post(_) do
    post =
      %Post{}
      |> Post.changeset(%{title: "Hello #{:erlang.unique_integer()}!", body: "Bodybuilder."})
      |> Repo.insert!()
      |> TaggerImpl.set_labels(@labels)
      |> reload

    {:ok, post: post}
  end

  defp reload(%{id: id}),
    do: Repo.get!(Post, id)
end
