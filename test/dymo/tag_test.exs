defmodule Dymo.TagTest do
  use Dymo.DataCase, async: true

  alias Dymo.Repo
  alias Dymo.Tag
  alias Ecto.Changeset

  doctest Tag, import: true

  setup :label

  describe ".changeset/1" do
    test "casts w/o namespace", %{label: label} do
      cs =
        %{label: label}
        |> Tag.changeset()

      assert label == Changeset.get_field(cs, :label)
      assert [] == Changeset.get_field(cs, :ns)
    end

    test "casts w/ namespace", %{label: label} do
      cs =
        %{label: label, ns: nil}
        |> Tag.changeset()

      assert [] == Changeset.get_field(cs, :ns)

      cs =
        %{label: label, ns: :ns1}
        |> Tag.changeset()

      assert [:ns1] == Changeset.get_field(cs, :ns)

      cs =
        %{label: label, ns: [:ns1]}
        |> Tag.changeset()

      assert [:ns1] == Changeset.get_field(cs, :ns)

      cs =
        %{label: label, ns: [:ns1, :ns2]}
        |> Tag.changeset()

      assert [] == Changeset.get_field(cs, :ns)
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
      assert match?({"has already been taken", _}, errors[:label])
    end

    test "enforces label unicity per namespace", %{label: label} do
      %{label: label}
      |> Tag.changeset()
      |> Repo.insert!()

      ns = :"#{:erlang.unique_integer()}"

      res =
        %{label: label, ns: ns}
        |> Tag.changeset()
        |> Repo.insert()

      assert match?({:ok, %Tag{label: ^label, ns: _}}, res)

      res =
        %{label: label, ns: ns}
        |> Tag.changeset()
        |> Repo.insert()

      assert match?(
               {:error,
                %Changeset{valid?: false, errors: [label: {"has already been taken", _}]}},
               res
             )
    end
  end

  describe ".find_or_create!/1" do
    test "inserts the record when it doesn't exist", %{label: label} do
      tag = Tag.find_or_create!(label)
      assert %Tag{} = tag
      assert tag.id
      assert label == tag.label
    end

    test "inserts the record when it doesn't exist, w/ namespaces", %{label: label} do
      ns = :"#{:erlang.unique_integer()}"
      tag = Tag.find_or_create!({ns, label})

      assert match?(%Tag{label: ^label}, tag)

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
    do: {:ok, label: "label #{:erlang.unique_integer()}"}
end
