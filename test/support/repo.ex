defmodule Dymo.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :dymo,
    adapter: Ecto.Adapters.Postgres
end
