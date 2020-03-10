defmodule Dymo do
  @moduledoc false

  @spec repo() :: module
  def repo,
    do: :dymo |> Application.get_env(:ecto_repo)

  @spec create_missing_tags_by_default() :: bool
  def create_missing_tags_by_default(),
    do: :dymo |> Application.get_env(:create_missing_tags_by_default, false)
end
