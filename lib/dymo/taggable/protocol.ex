defprotocol Dymo.Taggable.Protocol do
  alias Ecto.Query
  alias Dymo.Tag

  @spec labels(t(), keyword) :: Query.t()
  def labels(taggable, opts \\ [])

  @spec add_labels(t(), Tag.label_or_labels(), keyword) :: t()
  def add_labels(taggable, lbls, opts \\ [])

  @spec set_labels(t(), Tag.label_or_labels(), keyword) :: t()
  def set_labels(taggable, lbls, opts \\ [])

  @spec remove_labels(t(), Tag.label_or_labels(), keyword) :: t()
  def remove_labels(taggable, lbls, opts \\ [])
end
