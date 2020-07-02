defmodule Dymo.TaggerImplTester do
  @moduledoc false
  alias Dymo.Tag

  defmacro __using__(opts) do
    schema = opts |> Keyword.get(:schema)
    primary_key = opts |> Keyword.get(:primary_key)
    join_table = opts |> Keyword.get(:join_table)

    quote do
      use Dymo.DataCase, async: false
      alias Dymo.{TaggerImpl, Repo}
      import Ecto.Query

      @schema unquote(schema)
      @primary_key unquote(primary_key)
      @join_table unquote(join_table)

      @labels1 ~w(t11 t12 t13)
      @labels2 ~w(t21 t22 t23)
      @labels3 ~w(t31 t32 t33)
      @labels4 ~w(t41 t42 t43)
      @unassignable ~w(tna11 tna12)
      @nonexistent ~w(tn1 tn2 tn3)

      setup :taggables

      describe ".labels/4" do
        test "returns the tagged labels", %{posts: [p1, p2]} do
          assert @labels1 == p1 |> taggable_labels()
          assert @labels2 == p2 |> taggable_labels()
        end

        test "returns the tagged labels in a given namespace", %{posts: [p1 | _]} do
          p1 |> TaggerImpl.set_labels(@labels3, ns: :ns3, create_missing: true)
          assert @labels3 == p1 |> taggable_labels(ns: :ns3)
        end
      end

      describe ".set_labels/3" do
        test "overwrites existing labels", %{posts: [p1 | _]} do
          p1 |> TaggerImpl.set_labels(@labels3, create_missing: true)
          assert @labels3 == p1 |> taggable_labels()
        end

        test "overwrites existing labels with the same namespace", %{posts: [p1 | _]} do
          p1 |> TaggerImpl.set_labels(@labels4, ns: :ns1, create_missing: true)
          assert @labels1 == p1 |> taggable_labels()
          assert @labels4 == p1 |> taggable_labels(ns: :ns1)
        end

        test "can handle namespaces directly on tags", %{posts: [p1, p2]} do
          p1 |> TaggerImpl.set_labels(tuppleify(@labels4, :ns3), create_missing: true)

          p2
          |> TaggerImpl.set_labels(tuppleify(@labels3, :ns3) ++ tuppleify(@labels4, :ns4),
            create_missing: true
          )

          assert @labels4 == p1 |> taggable_labels(ns: :ns3)
          assert @labels3 == p2 |> taggable_labels(ns: :ns3)
          assert @labels4 == p2 |> taggable_labels(ns: :ns4)
        end

        test "only uses the optional namespace when none is found on tags", %{posts: [p1 | _]} do
          p1
          |> TaggerImpl.set_labels(@labels1 ++ tuppleify(@labels2, :ns2),
            ns: :ns1,
            create_missing: true
          )

          assert @labels1 == p1 |> taggable_labels(ns: :ns1)
          assert @labels2 == p1 |> taggable_labels(ns: :ns2)
        end

        test "can be prevented from creating new tags", %{posts: [p1, p2]} do
          p1 |> TaggerImpl.set_labels(@nonexistent)
          p2 |> TaggerImpl.set_labels(@nonexistent, ns: :ns2)
          assert p1 |> taggable_labels() |> Enum.empty?()
          assert p2 |> taggable_labels(ns: :ns2) |> Enum.empty?()
        end

        test "does not attach tags that are unassignable", %{posts: [p1 | _]} do
          create_unassignable_labels(nil)
          p1 |> TaggerImpl.set_labels(@unassignable, ns: :ns1, create_missing: true)
          assert [] == p1 |> taggable_labels(ns: :ns1)
        end

        test "attaches assignable tags when mixed with unassignable tags", %{posts: [p1 | _]} do
          create_unassignable_labels(nil)
          p1 |> TaggerImpl.set_labels(@unassignable ++ @labels1, ns: :ns1, create_missing: true)
          assert @labels1 == p1 |> taggable_labels(ns: :ns1)
        end
      end

      describe ".add_labels/{2,3}" do
        test "adds the labels", %{posts: [p1, p2]} do
          p1 |> TaggerImpl.add_labels(@labels3, create_missing: true)
          assert (@labels1 ++ @labels3) |> Enum.sort() == p1 |> taggable_labels()
          assert @labels2 == p2 |> taggable_labels
        end

        test "adds the labels in the given namespace", %{posts: [p1 | _]} do
          p1 |> TaggerImpl.add_labels(@labels3, create_missing: true)
          p1 |> TaggerImpl.add_labels(@labels3, ns: :ns1, create_missing: true)
          assert (@labels1 ++ @labels3) |> Enum.sort() == p1 |> taggable_labels()
          assert @labels3 == p1 |> taggable_labels(ns: :ns1)
        end

        test "can handle namespaces directly on tags", %{posts: [p1, p2]} do
          p1 |> TaggerImpl.add_labels(tuppleify(@labels4, :ns3), create_missing: true)

          p2
          |> TaggerImpl.add_labels(tuppleify(@labels3, :ns3) ++ tuppleify(@labels4, :ns4),
            create_missing: true
          )

          assert @labels4 == p1 |> taggable_labels(ns: :ns3)
          assert @labels3 == p2 |> taggable_labels(ns: :ns3)
          assert @labels4 == p2 |> taggable_labels(ns: :ns4)
        end

        test "only uses the optional namespace when none is found on tags", %{posts: [p1 | _]} do
          p1
          |> TaggerImpl.add_labels(@labels1 ++ tuppleify(@labels2, :ns2),
            ns: :ns1,
            create_missing: true
          )

          assert @labels1 == p1 |> taggable_labels(ns: :ns1)
          assert @labels2 == p1 |> taggable_labels(ns: :ns2)
        end

        test "can be prevented from creating new tags", %{posts: [p1, p2]} do
          p1 |> TaggerImpl.add_labels(@nonexistent)
          p2 |> TaggerImpl.add_labels(@nonexistent, ns: :ns2)
          assert @labels1 == p1 |> taggable_labels()
          assert @labels2 == p2 |> taggable_labels()
          assert p2 |> taggable_labels(ns: :ns2) |> Enum.empty?()
        end

        test "does not attach tags that are unassignable", %{posts: [p1 | _]} do
          create_unassignable_labels(nil)
          p1 |> TaggerImpl.add_labels(@unassignable, ns: :ns1, create_missing: true)
          assert [] == p1 |> taggable_labels(ns: :ns1)
        end

        test "attaches assignable tags when mixed with unassignable tags", %{posts: [p1 | _]} do
          create_unassignable_labels(nil)
          p1 |> TaggerImpl.add_labels(@unassignable ++ @labels1, ns: :ns1, create_missing: true)
          assert @labels1 == p1 |> taggable_labels(ns: :ns1)
        end
      end

      describe ".remove_labels/{2,3}" do
        test "removes the specified labels using combinations of namespaces", %{posts: [p1, p2]} do
          p1
          |> TaggerImpl.add_labels(@labels4, ns: :ns4, create_missing: true)
          |> TaggerImpl.remove_labels("t12")
          |> TaggerImpl.remove_labels("t42", ns: :ns4, create_missing: true)

          p2
          |> TaggerImpl.add_labels(@labels2, ns: :ns2, create_missing: true)
          |> TaggerImpl.add_labels(@labels4, ns: :ns4, create_missing: true)
          |> TaggerImpl.remove_labels("t12")
          |> TaggerImpl.remove_labels(["t22", {:ns4, "t42"}], ns: :ns2)

          assert @labels1 -- ["t12"] == p1 |> taggable_labels()
          assert @labels4 -- ["t42"] == p1 |> taggable_labels(ns: :ns4)
          assert @labels2 == p2 |> taggable_labels()
          assert @labels2 -- ["t22"] == p2 |> taggable_labels(ns: :ns2)
          assert @labels4 -- ["t42"] == p2 |> taggable_labels(ns: :ns4)
        end
      end

      describe ".all_labels/{2,3}" do
        test "gets tags from the given join table" do
          assert @labels1 ++ @labels2 ==
                   @join_table
                   |> TaggerImpl.all_labels(@primary_key)
                   |> Repo.all()
        end
      end

      describe ".labeled_with/4" do
        test "gets no entity at all when appropriate" do
          assert [] ==
                   @schema
                   |> TaggerImpl.labeled_with(@labels4, @join_table, @primary_key)
                   |> Repo.all()
        end

        test "gets a single entity when appropriate", %{posts: [p1 | _]} do
          assert [p1.id] ==
                   @schema
                   |> TaggerImpl.labeled_with("t11", @join_table, @primary_key)
                   |> select([t], t.id)
                   |> Repo.all()
        end

        test "gets multiple entities when appropriate", %{posts: [p1, p2]} do
          p1 |> TaggerImpl.add_labels(@labels3, create_missing: true)
          p2 |> TaggerImpl.add_labels(@labels3, create_missing: true)

          assert Enum.sort([p1.id, p2.id]) ==
                   @schema
                   |> TaggerImpl.labeled_with(@labels3, @join_table, @primary_key)
                   |> select([t], t.id)
                   |> order_by([t], t.id)
                   |> Repo.all()
        end
      end

      defp taggables(_) do
        posts =
          [@labels1, @labels2]
          |> Enum.map(
            &(@schema.struct()
              |> @schema.changeset(%{title: "Hello!", body: "Bodybuilder."})
              |> Repo.insert!()
              |> TaggerImpl.set_labels(&1, create_missing: true))
          )

        {:ok, posts: posts}
      end

      defp tuppleify(labels, ns) when is_list(labels),
        do: labels |> Enum.map(&tuppleify(&1, ns))

      defp tuppleify(label, ns) when is_binary(label),
        do: {ns, label}

      defp taggable_labels(taggable, opts \\ []),
        do:
          taggable
          |> TaggerImpl.labels(@join_table, @primary_key, opts)
          |> Repo.all()
          |> Enum.sort()

      defp create_unassignable_labels(_) do
        for label <- @unassignable do
          %{ns: :ns1, label: label, assignable: false}
          |> Tag.changeset()
          |> Repo.insert!()
        end
      end
    end
  end
end
