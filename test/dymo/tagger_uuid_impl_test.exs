defmodule Dymo.TaggerUuidImplTest do
  use Dymo.DataCase, async: true

  alias Dymo.Repo
  alias Dymo.Taggable
  alias Dymo.UUPost

  setup :create_labelled_post

  @labels1 ~w(tu1 tu2)
  @labels2 ~w(tu3 tu4)

  test ".set_labels/3", %{post: post} do
    post = Taggable.set_labels(post, nil, @labels2)
    labels = post.tags |> Enum.map(& &1.label)
    assert match?(@labels2, labels)
  end

  test ".all_labels/1" do
    assert match?(@labels1, UUPost |> Taggable.all_labels(nil) |> Repo.all())
  end

  test ".labels/1", %{post: post} do
    assert match?(@labels1, post |> Taggable.labels(nil) |> Repo.all())
  end

  defp create_labelled_post(_) do
    post =
      %UUPost{}
      |> UUPost.changeset(%{title: "Yo #{:erlang.unique_integer()}!", body: "Plop"})
      |> Repo.insert!(read_after_writes: true)
      |> Taggable.set_labels(nil, @labels1)
      |> reload()

    {:ok, post: post}
  end

  defp reload(%{id: id}), do: Repo.get!(UUPost, id)
end
