defmodule Dymo.TagTest do
  use Dymo.DataCase, async: true

  alias Dymo.Repo
  alias Dymo.Tag
  alias Ecto.Changeset

  doctest Tag, import: true

  setup :label

  describe ".changeset/1" do
    test "casts", %{label: label} do
      cs = %{label: label} |> Tag.changeset()
      assert label == Changeset.get_field(cs, :label)
      assert :root == Changeset.get_field(cs, :ns)
    end

    test "casts with namespace", %{label: label} do
      cs = label |> Tag.changeset()
      assert :root == Changeset.get_field(cs, :ns)

      cs = {:ns1, label} |> Tag.changeset()
      assert :ns1 == Changeset.get_field(cs, :ns)
    end

    test "enforces label unicity constraints", %{label: label} do
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

    test "enforces label unicity constraints with namespaces", %{label: label} do
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
    test "inserts the tag when it doesn't exist", %{label: label} do
      tag = label |> Tag.find_or_create!()
      assert %Tag{} = tag
      assert tag.id
      assert label == tag.label
    end

    test "inserts the tag when it doesn't exist, w/ namespaces", %{label: label} do
      ns = :"#{:erlang.unique_integer()}"
      tag = Tag.find_or_create!({ns, label})

      assert match?(%Tag{label: ^label, ns: ^ns}, tag)
    end

    test "gets the tag when it already exists", %{label: label} do
      tag1 = label |> Tag.find_or_create!()
      tag2 = label |> Tag.find_or_create!()
      assert tag1 == tag2
    end

    test "gets the namespaced tag when it already exists", %{label: label} do
      tag1 = {:foo, label} |> Tag.find_or_create!()
      tag2 = {:foo, label} |> Tag.find_or_create!()
      assert tag1 == tag2
    end
  end

  describe ".find_existing/1" do
    test "doesn't insert the tag when it doesn't exist", %{label: label} do
      tag = label |> Tag.find_existing()
      assert tag == nil
    end

    test "doesn't insert the namespaced tag when it doesn't exist", %{label: label} do
      tag = {:foo, label} |> Tag.find_existing()
      assert tag == nil
    end

    test "gets the tag when it already exists", %{label: label} do
      tag1 = label |> Tag.find_or_create!()
      tag2 = label |> Tag.find_existing()
      assert tag1 == tag2
    end

    test "gets the namespaced tag when it already exists", %{label: label} do
      tag1 = {:foo, label} |> Tag.find_or_create!()
      tag2 = {:foo, label} |> Tag.find_existing()
      assert tag1 == tag2
    end
  end

  defp label(_context),
    do: {:ok, label: "label #{:erlang.unique_integer()}"}
end
