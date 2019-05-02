defmodule Dymo.Tag.Ns do
  @moduledoc """
  Describes a tag's namespace
  """
  @behaviour Ecto.Type

  @sep ":"

  def type, do: :string

  def cast(nil), do: {:ok, []}

  def cast(ns) when is_list(ns) do
    ns
    |> Enum.reduce_while({:ok, []}, fn
      v, {:ok, acc} when is_atom(v) -> {:cont, {:ok, acc ++ [v]}}
      _, _ -> {:halt, :error}
    end)
  rescue
    ArgumentError -> :error
    FunctionClauseError -> :error
  end

  def cast(ns), do: ns |> List.wrap() |> cast()

  def load(data) when is_binary(data) do
    ns =
      data
      |> String.split(@sep)
      |> Enum.map(&String.to_existing_atom/1)

    {:ok, ns}
  end

  def load(_), do: :error

  def dump(data) when is_list(data),
    do: {:ok, Enum.join(data, @sep)}

  def dump(_), do: :error
end
