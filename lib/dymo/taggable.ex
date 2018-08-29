defmodule Dymo.Taggable do
  @moduledoc """
  Allows to easily make models taggable.

  To use this module, you can simply leverage the `use` macro inside
  your model module:

  ```elixir
  use Dymo.Taggable
  ```

  When doing so, the current module will be augmented by several functions:

  - `set_labels/2`
  - `add_labels/2`
  - `remove_labels/2`
  - `labels/0` and `labels/1`
  - `labeled_with/1`

  Doing so will require you to have a join table set up between the model and `Dymo.Tag`
  as well as a `many_to_many` relationship on your model.

  For more information about their usage and typings, have a look at the `Dymo.Tagger`
  behaviour and the `Dymo.TaggerImpl` implementation.
  """

  alias Dymo.Tagger

  defmacro __using__(opts) do
    impl = Keyword.get(opts, :implementation, Dymo.TaggerImpl)

    join_table = Keyword.get(opts, :join_table, Tagger.join_table(__CALLER__.module))
    join_key = Keyword.get(opts, :join_key, Tagger.join_key(__CALLER__.module))

    quote do
      alias Ecto.{Query, Schema}
      alias Dymo.Tagger

      @spec set_labels(Schema.t(), Tagger.label() | Tagger.labels()) :: Schema.t()
      defdelegate set_labels(struct, label_or_labels),
        to: unquote(impl)

      @spec add_labels(Schema.t(), Tagger.label() | Tagger.labels()) :: Schema.t()
      defdelegate add_labels(struct, label_or_labels),
        to: unquote(impl)

      @spec remove_labels(Schema.t(), Tagger.label() | Tagger.labels()) :: Schema.t()
      defdelegate remove_labels(struct, label_or_labels),
        to: unquote(impl)

      @spec labels :: Query.t()
      def labels(),
        do: unquote(impl).query_labels(unquote(join_table))

      @spec labels(Schema.t()) :: Query.t()
      def labels(%{tags: _} = taggable),
        do: unquote(impl).query_labels(taggable, unquote(join_table), unquote(join_key))

      @spec labeled_with(Tagger.label() | Tagger.labels()) :: Query.t()
      def labeled_with(label_or_labels),
        do:
          unquote(impl).query_labeled_with(
            __MODULE__,
            label_or_labels,
            unquote(join_table),
            unquote(join_key)
          )
    end
  end
end
