defmodule Dymo.TagTest do
  use Dymo.DataCase, async: true

  alias Ecto.Changeset
  alias Dymo.{Repo, Tag, Tag.Ns}
  doctest Tag, import: true

  setup :fixtures

  describe ".changeset/2 via create_changeset/1" do
    test "casts a string directly", %{label: label} do
      cs = label |> Tag.create_changeset()
      assert label == Changeset.get_field(cs, :label)
      assert :root == Changeset.get_field(cs, :ns)
    end

    test "casts label tupples directly", %{ns: ns, label: label} do
      cs = {ns, label} |> Tag.create_changeset()
      assert label == Changeset.get_field(cs, :label)
      assert ns == Changeset.get_field(cs, :ns)
    end

    test "casts maps as attributes", %{ns: ns, label: label} do
      cs = %{ns: ns, label: label} |> Tag.create_changeset()
      assert label == Changeset.get_field(cs, :label)
      assert ns == Changeset.get_field(cs, :ns)
    end

    test "handles string namespaces", %{ns: ns, label: label} do
      cs = {"#{ns}", label} |> Tag.create_changeset()
      assert ns == Changeset.get_field(cs, :ns)
    end

    test "handles nil namespaces", %{label: label} do
      cs = {nil, label} |> Tag.create_changeset()
      assert cs.valid?
      assert :root == Changeset.get_field(cs, :ns)
    end

    test "enforces label unicity constraints", %{label: label} do
      %{label: label} |> Tag.create_changeset() |> Repo.insert!()

      {:error, %{valid?: valid, errors: errors}} =
        %{label: label} |> Tag.create_changeset() |> Repo.insert()

      refute valid
      assert match?({"has already been taken", _}, errors[:label])
    end

    test "enforces label unicity constraints within namespaces", %{ns: ns, label: label} do
      %{label: label} |> Tag.create_changeset() |> Repo.insert!()
      ret1 = %{ns: ns, label: label} |> Tag.create_changeset() |> Repo.insert()
      ret2 = %{ns: ns, label: label} |> Tag.create_changeset() |> Repo.insert()
      assert match?({:ok, %Tag{label: ^label, ns: _}}, ret1)

      assert match?(
               {:error,
                %Changeset{valid?: false, errors: [label: {"has already been taken", _}]}},
               ret2
             )
    end

    test "doesn't mix namespaces while checking for unicity constraints", %{label: label} do
      %{label: label} |> Tag.create_changeset() |> Repo.insert!()
      {:ok, %{id: id1}} = %{ns: :foo, label: label} |> Tag.create_changeset() |> Repo.insert()
      {:ok, %{id: id2}} = %{ns: :bar, label: label} |> Tag.create_changeset() |> Repo.insert()

      assert id1 != id2
    end
  end

  describe ".cast/1" do
    test "can cast into a valid changeset", %{ns: ns, label: label} do
      tag = {ns, label} |> Tag.to_struct()
      assert match?(%Tag{ns: ^ns, label: ^label}, tag)
    end

    test "raises when the cast cannot be performed", %{label: label} do
      ret = catch_error({"bad namespace", label} |> Tag.to_struct())
      assert match?(%RuntimeError{}, ret)
    end
  end

  describe ".find_or_create!/1" do
    test "inserts new tags", %{label: label} do
      %{id: id} = tag = label |> Tag.find_or_create!()
      assert id
      assert match?(%Tag{ns: :root, label: ^label}, tag)
    end

    test "inserts new namespaced tags", %{ns: ns, label: label} do
      tag = Tag.find_or_create!({ns, label})
      assert match?(%Tag{ns: ^ns, label: ^label}, tag)
    end

    test "gets existing tags without inserting them", %{label: label} do
      %{id: id1} = label |> Tag.find_or_create!()
      %{id: id2} = label |> Tag.find_or_create!()
      assert id1 == id2
    end

    test "gets existing namespaced tags without inserting them", %{ns: ns, label: label} do
      %{id: id1} = {ns, label} |> Tag.find_or_create!()
      %{id: id2} = {ns, label} |> Tag.find_or_create!()
      assert id1 == id2
    end

    test "respects namespaces", %{ns: ns, label: label} do
      %{ns: ns1, id: id1, label: label1} = {ns, label} |> Tag.find_or_create!()
      %{ns: ns2, id: id2, label: label2} = {:foo, label} |> Tag.find_or_create!()
      assert ns == ns1
      assert ns1 != ns2
      assert label == label1
      assert label1 == label2
      assert id1 != id2
    end
  end

  describe ".find_existing/1" do
    test "doesn't insert a tag when it doesn't exist", %{label: label} do
      tag = label |> Tag.find_existing()
      assert tag == nil
    end

    test "doesn't insert a namespaced tag when it doesn't exist", %{label: label} do
      tag = {:foo, label} |> Tag.find_existing()
      assert tag == nil
    end

    test "gets a tag when it exists", %{label: label} do
      %{id: id1} = label |> Tag.find_or_create!()
      %{id: id2} = label |> Tag.find_existing()
      assert id1 == id2
    end

    test "gets a namespaced tag when it exists", %{ns: ns, label: label} do
      %{id: id1} = {ns, label} |> Tag.find_or_create!()
      %{id: id2} = {ns, label} |> Tag.find_existing()
      assert id1 == id2
    end

    test "respects namespaces", %{ns: ns, label: label} do
      {ns, label} |> Tag.find_or_create!()
      res = {:foo, label} |> Tag.find_existing()
      refute res
    end
  end

  defp fixtures(_context),
    do: {:ok, ns: :"ns #{:erlang.unique_integer()}", label: "label #{:erlang.unique_integer()}"}
end
