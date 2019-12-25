defmodule Dymo.TaggerUuidImplTest do
  use Dymo.DataCase, async: true

  alias Dymo.Repo
  alias Dymo.Taggable
  alias Dymo.UUPost

  setup :create_labelled_post

  @labels1 ~w(tu1 tu2)
  @labels2 ~w(tu3 tu4)

  test ".set_labels/3", %{post: post} do
    post = Taggable.set_labels(post, @labels2)
    labels = post.tags |> Enum.map(& &1.label)
    assert match?(@labels2, labels)
  end

  test ".all_labels/{1,2}" do
    ret = UUPost |> Taggable.all_labels() |> Repo.all()
    assert match?(@labels1, ret)
  end

  test ".labels/1", %{post: post} do
    ret = post |> Taggable.labels() |> Repo.all()
    assert match?(@labels1, ret)
  end

  defp create_labelled_post(_) do
    post =
      %UUPost{}
      |> UUPost.changeset(%{title: "Yo #{:erlang.unique_integer()}!", body: "Plop"})
      |> Repo.insert!(read_after_writes: true)
      |> Taggable.set_labels(@labels1)

    {:ok, post: post}
  end
end
