defmodule Dymo.Taggable do
  @moduledoc """
  Allows to easily make models taggable.

  To use this module, you can simply leverage the `use` macro inside
  your model module:

  ```elixir
  use Dymo.Taggable
  ```

  Doing so will require you to have a join table set up between the model and `Dymo.Tag`
  as well as a `many_to_many` relationship on your model (or use the `tag()` macro to declare
  the relationship automatically).

  For more information about their usage and typings, have a look at the `Dymo.Tagger`
  behaviour and the `Dymo.TaggerImpl` implementation.
  """
  require Dymo.Taggable.Protocol

  alias Ecto.{Query, Schema}
  alias Dymo.{Tag, Tagger}
  alias Dymo.Taggable.Protocol

  @type t :: Protocol.t()

  defmacro __using__(opts) do
    impl = Keyword.get(opts, :implementation, Dymo.TaggerImpl)

    join_table = Keyword.get(opts, :join_table, Tagger.join_table(__CALLER__.module))
    join_key = Keyword.get(opts, :join_key, Tagger.join_key(__CALLER__.module))

    Module.put_attribute(__CALLER__.module, :tagger_impl, impl)
    Module.put_attribute(__CALLER__.module, :join_table, join_table)
    Module.put_attribute(__CALLER__.module, :join_key, join_key)

    quote do
      import Dymo.Taggable

      @tagger_impl unquote(impl)
      @before_compile Dymo.Taggable
    end
  end

  defmacro __before_compile__(env) do
    impl = Module.get_attribute(env.module, :tagger_impl)
    join_table = Module.get_attribute(env.module, :join_table)
    join_key = Module.get_attribute(env.module, :join_key)

    quote do
      require Dymo.Taggable.Protocol

      alias Ecto.{Query, Schema}
      alias Dymo.Tag

      defimpl Dymo.Taggable.Protocol do
        @spec labels(Dymo.Taggable.t(), keyword) :: Query.t()
        def labels(taggable, opts \\ []),
          do: unquote(impl).labels(taggable, unquote(join_table), unquote(join_key), opts)

        @spec set_labels(Dymo.Taggable.t(), Tag.label_or_labels(), keyword) :: Schema.t()
        def set_labels(taggable, labels, opts \\ []),
          do: unquote(impl).set_labels(taggable, labels, opts)

        @spec add_labels(Dymo.Taggable.t(), Tag.label_or_labels(), keyword) :: Schema.t()
        def add_labels(taggable, labels, opts \\ []),
          do: unquote(impl).add_labels(taggable, labels, opts)

        @spec remove_labels(Dymo.Taggable.t(), Tag.label_or_labels(), keyword) :: Schema.t()
        def remove_labels(taggable, labels, opts \\ []),
          do: unquote(impl).remove_labels(taggable, labels, opts)
      end

      @spec all_labels(keyword) :: Query.t()
      def all_labels(opts \\ []),
        do:
          unquote(impl).all_labels(
            unquote(join_table),
            unquote(join_key),
            opts
          )

      @spec labeled_with(Tag.label_or_labels(), keyword) :: Query.t()
      def labeled_with(label_or_labels, opts \\ []),
        do:
          unquote(impl).labeled_with(
            __MODULE__,
            label_or_labels,
            unquote(join_table),
            unquote(join_key),
            opts
          )
    end
  end

  @doc "Use this macro in your Ecto schema to add `tags` field."
  defmacro tags do
    taggings =
      __CALLER__.module
      |> Module.get_attribute(:join_table)
      |> case do
        nil -> raise "Please declare `use #{__MODULE__}` before using `#{__MODULE__}.tags/1`."
        taggings -> taggings
      end

    quote do
      many_to_many :tags, Dymo.Tag,
        join_through: unquote(taggings),
        on_replace: :delete,
        unique: true
    end
  end

  @doc "Returns all labels in the given namespace."
  @spec labels(t(), keyword) :: Query.t()
  defdelegate labels(taggable, opts \\ []), to: Protocol

  @doc "Sets all labels with the given namespace, replacing existing ones."
  @spec set_labels(t(), Tag.label_or_labels(), keyword) :: Schema.t()
  defdelegate set_labels(taggable, lbls, opts \\ []), to: Protocol

  @doc "Adds labels to the given namespace."
  @spec add_labels(t(), Tag.label_or_labels(), keyword) :: Schema.t()
  defdelegate add_labels(taggable, lbls, opts \\ []), to: Protocol

  @doc "Remove labels from the given namespace."
  @spec remove_labels(t(), Tag.label_or_labels(), keyword) :: Schema.t()
  defdelegate remove_labels(taggable, label_or_labels, opts \\ []), to: Protocol

  @doc "Returns all labels associad with the given schema."
  @spec all_labels(module, keyword) :: Query.t()
  def all_labels(module, opts \\ []), do: module.all_labels(opts)

  @doc "Returns all objects of given type labeled with given labels."
  @spec labeled_with(module, Tag.label_or_labels(), keyword) :: Query.t()
  def labeled_with(module, tags, opts \\ []), do: module.labeled_with(tags, opts)
end
