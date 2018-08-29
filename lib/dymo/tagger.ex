defmodule Dymo.Tagger do
  @moduledoc """
  Defines the functions required for a tagger to be compabible
  with the Dymo.Taggable macro.
  """
  use Ecto.Schema
  alias Ecto.{Query, Schema}

  @typedoc "A single label is a string."
  @type label :: String.t()
  @typedoc "A list of labels."
  @type labels :: [String.t()]
  @typedoc "Either a single label or a list of them."
  @type label_or_labels :: label | labels
  @typedoc "A join table name is a string."
  @type join_table :: String.t()
  @typedoc "A join key is an atom."
  @type join_key :: atom

  @doc """
  Sets the labels associated with an instance of a model.

  If any other labels are associated to the given model, they are
  discarded if they are not part of the list of passed new labels.

  See `Dymo.TaggerImpl.set_labels/2`.
  """
  @callback set_labels(Schema.t(), label_or_labels) :: Schema.t()

  @doc """
  Adds labels to a given instance of a model.

  See `Dymo.TaggerImpl.add_labels/2`.
  """
  @callback add_labels(Schema.t(), label_or_labels) :: Schema.t()

  @doc """
  Removes labels from a given instance of a model.

  See `Dymo.TaggerImpl.remove_labels/2`.
  """
  @callback remove_labels(Schema.t(), label_or_labels) :: Schema.t()

  @doc """
  Retrieves labels associated with an target. The target
  could be either a module or a schema.

  See `Dymo.TaggerImpl.query_labels/1`.
  """
  @callback query_labels(module | String.t() | Schema.t()) :: Query.t()

  @doc """
  Retrieves labels associated with an target.

  See `Dymo.TaggerImpl.query_labels/3`.
  """
  @callback query_labels(Schema.t(), join_table, join_key) :: Query.t()

  @doc """
  Queries models that are tagged with the given labels.

  See `Dymo.query_labeled_with.query_labels/2`.
  """
  @callback query_labeled_with(module, label_or_labels) :: Query.t()

  @doc """
  Queries models that are tagged with the given labels.

  See `Dymo.query_labeled_with.query_labels/4`.
  """
  @callback query_labeled_with(module, label_or_labels, join_table, join_key) :: Query.t()

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
    |> String.downcase()
  end
end
