defmodule Dymo.TaggerUuidImplTest do
  use Dymo.DataCase, async: true

  alias Dymo.Repo
  alias Dymo.UUPost

  setup :create_labelled_post

  @labels1 ~w(tu1 tu2)
  @labels2 ~w(tu3 tu4)

  test ".set_labels/2", %{post: post} do
    post = UUPost.set_labels(post, @labels2)

    labels = post.tags |> Enum.map(& &1.label)

    assert match?(@labels2, labels)
  end

  test ".all_labels/0" do
    assert match?(@labels1, UUPost.all_labels() |> Repo.all())
  end

  test ".labels/1", %{post: post} do
    assert match?(@labels1, post |> UUPost.labels() |> Repo.all())
  end

  defp create_labelled_post(_) do
    post =
      %UUPost{}
      |> UUPost.changeset(%{title: "Yo #{:erlang.unique_integer()}!", body: "Plop"})
      |> Repo.insert!(read_after_writes: true)
      |> UUPost.set_labels(@labels1)
      |> reload()

    {:ok, post: post}
  end

  defp reload(%{id: id}), do: Repo.get!(UUPost, id)
end
