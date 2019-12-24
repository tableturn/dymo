defmodule Dymo do
  @moduledoc false

  @repo Application.get_env(:dymo, :ecto_repo)

  @spec repo() :: module
  def repo, do: @repo
end
