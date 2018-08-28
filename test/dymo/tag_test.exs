defmodule Dymo.TagTest do
  use Dymo.DataCase, async: true
  alias Dymo.Repo
  alias Dymo.Tag
  doctest Tag, import: true

  setup :label

  describe ".changeset/1" do
    test "casts the label attribute", %{label: label} do
      %{changes: changes} = Tag.changeset(%{label: label})

      assert label == changes[:label]
    end

    test "enforces label unicity", %{label: label} do
      %{label: label}
      |> Tag.changeset()
      |> Repo.insert!()

      {:error, %{valid?: valid, errors: errors}} =
        %{label: label}
        |> Tag.changeset()
        |> Repo.insert()

      refute valid
      assert errors[:label] == {"has already been taken", []}
    end
  end

  describe ".find_or_create!/1" do
    test "inserts the record when it doesn't exist", %{label: label} do
      tag = Tag.find_or_create!(label)
      assert %Tag{} = tag
      assert tag.id
      assert label == tag.label
    end

    test "gets the record when it already exists", %{label: label} do
      tag1 = Tag.find_or_create!(label)
      tag2 = Tag.find_or_create!(label)
      assert tag1 == tag2
    end
  end

  defp label(_context),
    do: {:ok, label: "#{Faker.Name.first_name()} #{:erlang.unique_integer()}"}
end
