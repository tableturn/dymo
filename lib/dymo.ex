defmodule Dymo do
  @moduledoc false

  @spec repo() :: module
  def repo, do: :dymo |> Application.get_env(:ecto_repos) |> hd()
end
