defmodule Dymo.Tagger do
  @moduledoc """
  Defines the functions required for a tagger to be compabible
  with the Dymo.Taggable macro.
  """
  use Ecto.Schema
  alias Ecto.{Query, Schema}

  @type label :: String.t()
  @type labels :: [String.t()]
  @type join_table :: String.t()
  @type join_key :: atom

  @callback set_labels(Schema.t(), label | labels) :: Schema.t()
  @callback add_labels(Schema.t(), label | labels) :: Schema.t()
  @callback remove_labels(Schema.t(), label | labels) :: Schema.t()
  @callback query_labels(module | String.t() | Schema.t()) :: Query.t()
  @callback query_labels(Schema.t(), join_table, join_key) :: Query.t()
  @callback query_labeled_with(module, label | labels) :: Query.t()
  @callback query_labeled_with(module, label | labels, join_table, join_key) :: Query.t()

  @spec join_table(Schema.t() | module) :: String.t()
  def join_table(module),
    do:
      module
      |> normalize()
      |> singularize()
      |> Inflex.pluralize()
      |> (fn plural -> "#{plural}_tags" end).()

  @spec join_key(Schema.t() | module) :: atom
  def join_key(module),
    do:
      module
      |> normalize
      |> singularize
      |> (fn singular -> :"#{singular}_id" end).()

  @spec normalize(Schema.t() | module) :: module
  defp normalize(%{__struct__: module}), do: module
  defp normalize(module), do: module

  @spec singularize(module) :: String.t()
  defp singularize(module),
    do:
      module
      |> Module.split()
      |> List.last()
      |> String.downcase()
end
