defmodule Dymo.Tagging do
  @moduledoc """
  This module provides functionality dedicated to handling tag data.

  It essentially aims at maintaining singleton labels in a `tags` table
  and exposes helper functions to ease their creation.
  """
  alias Dymo.Tag
  use Ecto.Schema

  @typedoc "Defines simple tags identified by a unique label."
  @type t :: %__MODULE__{}

  schema "taggings" do
    # Regular fields.
    belongs_to :tag, Tag
    belongs_to :post, Dymo.Post
    belongs_to :uu_post, Dymo.UUPost

    # The scope for this tagging.
    field :scope, :string
  end
end
