defmodule Dymo.Tag.Ns do
  @moduledoc "Describes a tag's namespace."
  use Ecto.Type

  @type t :: atom

  @doc """
  This is a configurable parametter allowing to change the atom that will
  be used for unspecified or `nil` namespaces.

  ## Examples

      iex> root_namespace()
      :root
  """
  @spec root_namespace :: atom
  def root_namespace,
    do: Application.get_env(:dymo, :root_namespace, :root)

  @doc """
  The `type/0` function describe what underlying type should be used for
  storage.

  ## Examples

      iex> type()
      :string
  """
  @impl Ecto.Type
  @spec type :: :string
  def type,
    do: :string

  @doc """
  We use `cast/1` to transform and normalize external data into internal
  data, eg when using `Ecto.Changeset.cast`.

  ## Examples

  ## Examples

      iex> nil |> cast()
      {:ok, root_namespace()}
      iex> root_namespace() |> cast()
      {:ok, root_namespace()}
      iex> "blue" |> cast()
      {:ok, :blue}
      iex> :blue |> cast()
      {:ok, :blue}
      iex> "non existent atom" |> cast()
      :error
      iex> 3 |> cast()
      :error
      iex> [] |> cast()
      :error
  """
  @impl Ecto.Type
  @spec cast(nil | String.t() | t) :: {:ok, t} | :error
  def cast(nil),
    do: root_namespace() |> cast()

  def cast(atom) when is_atom(atom),
    do: {:ok, atom}

  def cast(string) when is_binary(string) do
    string
    |> String.to_existing_atom()
    |> cast()
  rescue
    _ -> :error
  end

  def cast(_),
    do: :error

  @spec cast!(nil | String.t() | t) :: t
  def cast!(value) do
    {:ok, ret} = value |> cast()
    ret
  end

  @doc """
  We use `load/1` to load data from the database into a normalized form,
  very much like how `cast/1` loads data from the outside world.

  ## Examples

      iex> nil |> load()
      {:ok, root_namespace()}
      iex> root_namespace() |> load()
      {:ok, root_namespace()}
      iex> "blue" |> load()
      {:ok, :blue}
      iex> :blue |> load()
      {:ok, :blue}
      iex> "non existent atom" |> load()
      :error
      iex> 3 |> load()
      :error
      iex> [] |> load()
      :error
  """
  @impl Ecto.Type
  @spec load(any) :: :error | {:ok, t}
  def load(value),
    do: value |> cast()

  @doc """
  The `dump/1` function converts data into a format that can be stored in the
  database using the type described by `type/0`.

  ## Examples

      iex> nil |> dump()
      {:ok, "root"}
      iex> root_namespace() |> dump()
      {:ok, "root"}
      iex> :blue |> dump()
      {:ok, "blue"}
      iex> "blue" |> dump()
      :error
      iex> 3 |> dump()
      :error
      iex> [] |> dump()
      :error
  """
  @impl Ecto.Type
  @spec dump(any) :: :error | {:ok, [atom]}
  def dump(nil),
    do: {:ok, "root"}

  def dump(value) when is_atom(value),
    do: {:ok, "#{value}"}

  def dump(_),
    do: :error
end
