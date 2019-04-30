defmodule Dymo.Tag.Ns do
  @moduledoc """
  Describes a tag's namespace
  """
  @behaviour Ecto.Type

  def type, do: {:array, :string}

  def cast(nil), do: {:ok, []}

  def cast(ns) when is_list(ns) do
    ns =
      ns
      |> Enum.map(fn
        v when is_atom(v) -> v
        v when is_binary(v) -> String.to_existing_atom(v)
      end)

    {:ok, ns}
  rescue
    ArgumentError -> :error
    FunctionClauseError -> :error
  end

  def cast(ns), do: ns |> List.wrap() |> cast()

  def load(data) when is_list(data),
    do: {:ok, Enum.map(data, &String.to_existing_atom/1)}

  def load(_), do: :error

  def dump(data) when is_list(data),
    do: {:ok, Enum.map(data, &Atom.to_string/1)}

  def dump(_), do: :error
end
