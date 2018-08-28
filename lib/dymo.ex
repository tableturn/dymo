defmodule Dymo do
  @moduledoc false

  @spec repo() :: module
  def repo, do: Application.get_env(:dymo, :repo)
end
