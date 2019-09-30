defmodule Dymo.Tag.Ns do
  @moduledoc "Describes a tag's namespace."
  use Ecto.Type

  @type t :: atom | [atom]

  @sep ":"

  @impl Ecto.Type
  @spec type :: :string
  def type,
    do: :string

  @spec cast!(t) :: binary
  def cast!(data) do
    {:ok, ns} = cast(data)
    ns
  end

  @impl Ecto.Type
  @spec cast(t) :: {:ok, binary} | :error
  def cast(nil),
    do: {:ok, []}

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

  def cast(ns),
    do:
      ns
      |> List.wrap()
      |> cast()

  @impl Ecto.Type
  @spec load(any) :: :error | {:ok, t}
  def load(data) when is_binary(data) do
    ns =
      data
      |> String.split(@sep, trim: true)
      |> Enum.map(&String.to_existing_atom/1)

    {:ok, ns}
  end

  def load(_),
    do: :error

  @impl Ecto.Type
  @spec dump(any) :: :error | {:ok, binary}
  def dump([]),
    do: {:ok, ":"}

  def dump(data) when is_list(data),
    do: {:ok, Enum.join(data, @sep)}

  def dump(_),
    do: :error
end
