defprotocol Dymo.Taggable.Protocol do
  alias Dymo.Tag
  alias Dymo.Tag.Ns

  @spec set_labels(t(), Tag.label_or_labels()) :: t()
  @spec set_labels(t(), Ns.t() | nil, Tag.label_or_labels()) :: t()
  def set_labels(taggable, ns \\ nil, lbls)

  @spec add_labels(t(), Tag.label_or_labels()) :: t()
  @spec add_labels(t(), Ns.t() | nil, Tag.label_or_labels()) :: t()
  def add_labels(taggable, ns \\ nil, lbls)

  @spec remove_labels(t(), Tag.label_or_labels()) :: t()
  @spec remove_labels(t(), Ns.t() | nil, Tag.label_or_labels()) :: t()
  def remove_labels(taggable, ns \\ nil, lbls)

  @spec labels(t) :: t()
  @spec labels(t(), Ns.t() | nil) :: t()
  def labels(taggable, ns \\ nil)
end
