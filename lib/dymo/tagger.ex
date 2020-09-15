defmodule Dymo.Tagger do
  @moduledoc """
  Defines the functions required for a tagger to be compabible
  with the Dymo.Taggable macro.
  """
  use Ecto.Schema

  alias Dymo.Tag
  alias Ecto.{Query, Schema}

  @typedoc "A join table name is a string."
  @type join_table :: String.t()
  @typedoc "A join key is an atom."
  @type join_key :: atom

  @doc "See `Dymo.TaggerImpl.tags/{3,4}`."
  @callback tags(Schema.t(), join_table, join_key) :: Query.t()
  @doc "See `Dymo.TaggerImpl.labels/{3,4}`."
  @callback labels(Schema.t(), join_table, join_key) :: Query.t()
  @doc "See `Dymo.TaggerImpl.labels/{3,4}`."
  @callback labels(Schema.t(), join_table, join_key, keyword) :: Query.t()

  @doc "See `Dymo.TaggerImpl.set_labels/3`."
  @callback set_labels(Schema.t(), Tag.label_or_labels()) :: Schema.t()
  @doc "See `Dymo.TaggerImpl.set_labels/3`."
  @callback set_labels(Schema.t(), Tag.label_or_labels(), keyword) :: Schema.t()

  @doc "See `Dymo.TaggerImpl.add_labels/{2,3}`."
  @callback add_labels(Schema.t(), Tag.label_or_labels()) :: Schema.t()
  @doc "See `Dymo.TaggerImpl.add_labels/{2,3}`."
  @callback add_labels(Schema.t(), Tag.label_or_labels(), keyword) :: Schema.t()

  @doc "See `Dymo.TaggerImpl.remove_labels/3`."
  @callback remove_labels(Schema.t(), Tag.label_or_labels()) :: Schema.t()
  @doc "See `Dymo.TaggerImpl.remove_labels/3`."
  @callback remove_labels(Schema.t(), Tag.label_or_labels(), keyword) :: Schema.t()

  @doc "See `Dymo.TaggerImpl.all_labels/3`."
  @callback all_labels(join_table, join_key) :: Query.t()
  @doc "See `Dymo.TaggerImpl.all_labels/3`."
  @callback all_labels(join_table, join_key, keyword) :: Query.t()

  @doc "See `Dymo.labeled_with.labels/4`."
  @callback labeled_with(module, Tag.label_or_labels(), join_table, join_key) ::
              Query.t()
  @doc "See `Dymo.labeled_with.labels/4`."
  @callback labeled_with(module, Tag.label_or_labels(), join_table, join_key, keyword) ::
              Query.t()

  @doc """
  Use this module to implements alternative `Ecto.Tagger`

  By default, all functions are delegated to `Ecto.Tagger` but can be overriden
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Dymo.Tagger

      import Ecto.Query
      alias Dymo.TaggerImpl

      defdelegate labels(struct, join_table, join_key, opts \\ []), to: TaggerImpl
      defdelegate set_labels(struct, label_or_labels, opts \\ []), to: TaggerImpl
      defdelegate add_labels(struct, label_or_labels, opts \\ []), to: TaggerImpl
      defdelegate remove_labels(struct, label_or_labels, opts \\ []), to: TaggerImpl

      defdelegate all_labels(join_table, join_key, opts \\ []), to: TaggerImpl

      defdelegate labeled_with(module, label_or_labels, join_table, join_key, opts \\ []),
        to: TaggerImpl

      defoverridable labels: [3, 4],
                     set_labels: [2, 3],
                     add_labels: [2, 3],
                     remove_labels: [2, 3],
                     all_labels: [2, 3],
                     labeled_with: [4, 5]
    end
  end

  @doc """
  A helper function that generates the join table name to be used
  for a given schema or model.

  ## Examples

      iex> Tagger.join_table(Dymo.Post)
      "posts_tags"

      iex> Tagger.join_table(%Dymo.Post{})
      "posts_tags"

      iex> Tagger.join_table(Person)
      "people_tags"
  """
  @spec join_table(Schema.t() | module | String.t()) :: String.t()
  def join_table(module),
    do:
      module
      |> singularize
      |> Inflex.pluralize()
      |> (&"#{&1}_tags").()

  @doc """
  A helper function that helps computing the field name to use
  in taggings queries.

  ## Examples

      iex> Tagger.join_key(Dymo.Post)
      :post_id

      iex> Tagger.join_key(%Dymo.Post{})
      :post_id

      iex> Tagger.join_key(Person)
      :person_id
  """
  @spec join_key(Schema.t() | module | String.t()) :: atom
  def join_key(module),
    do:
      module
      |> singularize
      |> (fn singular -> :"#{singular}_id" end).()

  @spec singularize(Schema.t() | module | String.t()) :: String.t()
  def singularize(target) do
    target
    |> case do
      module when is_atom(module) -> to_string(module)
      %{__struct__: module} -> to_string(module)
      otherwise -> otherwise
    end
    |> String.split(".")
    |> List.last()
    |> Macro.underscore()
  end
end
