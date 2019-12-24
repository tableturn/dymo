defmodule Dymo.Tag.Ns do
  @moduledoc "Describes a tag's namespace."
  use Ecto.Type

  @type t :: nil | atom

  @impl Ecto.Type
  @spec type :: :string
  def type,
    do: :string

  @impl Ecto.Type
  @spec cast(t) :: {:ok, t} | :error
  def cast(nil),
    do: {:ok, :root}

  def cast(value) when is_atom(value),
    do: {:ok, value}

  def cast(_),
    do: :error

  @spec cast!(t) :: t
  def cast!(data) do
    {:ok, ns} = cast(data)
    ns
  end

  @impl Ecto.Type
  @spec load(any) :: :error | {:ok, t}
  def load(nil),
    do: {:ok, :root}

  def load(value) when is_binary(value),
    do: {:ok, String.to_existing_atom(value)}

  def load(_),
    do: :error

  @impl Ecto.Type
  @spec dump(any) :: :error | {:ok, [atom]}
  def dump(nil),
    do: {:ok, "root"}

  def dump(value) when is_atom(value),
    do: {:ok, "#{value}"}

  def dump(_),
    do: :error
end
