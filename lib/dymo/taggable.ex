defmodule Dymo.Taggable do
  @moduledoc """
  Allows to easily make models taggable.
  """

  alias Dymo.Tagger

  defmacro __using__(opts) do
    impl = Keyword.get(opts, :implementation, Dymo.TaggerImpl)

    join_table = Tagger.join_table(__CALLER__.module)
    join_key = Tagger.join_key(__CALLER__.module)

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
