defmodule Dymo.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Dymo.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Dymo.Repo, {:shared, self()})
    end

    :ok
  end
end
