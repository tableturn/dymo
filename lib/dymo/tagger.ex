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

  @doc """
  Adds labels to a given instance of a model.

  See `Dymo.TaggerImpl.add_labels/3`.
  """
  @callback add_labels(Schema.t(), Tag.ns() | nil, Tag.string_or_strings()) :: Schema.t()

  @doc """
  Sets the labels associated with an instance of a model.

  If any other labels are associated to the given model, they are
  discarded if they are not part of the list of passed new labels.

  See `Dymo.TaggerImpl.set_labels/3`.
  """
  @callback set_labels(Schema.t(), Tag.ns() | nil, Tag.string_or_strings()) :: Schema.t()

  @doc """
  Removes labels from a given instance of a model.

  See `Dymo.TaggerImpl.remove_labels/3`.
  """
  @callback remove_labels(Schema.t(), Tag.ns(), Tag.string_or_strings()) :: Schema.t()

  @doc """
  Generates query for retrieving labels associated with a schema.

  See `Dymo.TaggerImpl.query_all_labels/3`.
  """
  @callback query_all_labels(join_table, join_key, Tag.ns() | nil) :: Query.t()

  @doc """
  Generates query for retrieving labels associated with a schema's
  instance.

  See `Dymo.TaggerImpl.query_labels/{3,4}`.
  """
  @callback query_labels(Schema.t(), join_table, join_key, Tag.ns() | nil) :: Query.t()

  @doc """
  Queries models that are tagged with the given labels.

  See `Dymo.query_labeled_with.query_labels/4`.
  """
  @callback query_labeled_with(module, Tag.label_or_labels(), join_table, join_key) :: Query.t()

  @doc """
  Use this module to implements alternative `Ecto.Tagger`

  By default, all functions are delegated to `Ecto.Tagger` but can be overriden
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Dymo.Tagger

      import Ecto.Query

      alias Dymo.TaggerImpl

      defdelegate set_labels(struct, ns, label_or_labels), to: TaggerImpl
      defdelegate add_labels(struct, ns, label_or_labels), to: TaggerImpl
      defdelegate remove_labels(struct, ns, label_or_labels), to: TaggerImpl
      defdelegate query_all_labels(join_table, join_key, ns), to: TaggerImpl
      defdelegate query_labels(struct, join_table, join_key), to: TaggerImpl
      defdelegate query_labels(struct, join_table, join_key, ns), to: TaggerImpl

      defdelegate query_labeled_with(module, label_or_labels, join_table, join_key),
        to: TaggerImpl

      defoverridable set_labels: 3,
                     add_labels: 3,
                     remove_labels: 3,
                     query_all_labels: 3,
                     query_labels: [3, 4],
                     query_labeled_with: 4
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
      |> (fn plural -> "#{plural}_tags" end).()

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
