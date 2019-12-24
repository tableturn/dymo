defprotocol Dymo.Taggable.Protocol do
  alias Dymo.Tag
  alias Dymo.Tag.Ns

  @spec add_labels(t(), Ns.t(), Tag.label_or_labels(), keyword) :: t()
  def add_labels(taggable, ns, lbls, opts \\ [])

  @spec set_labels(t(), Ns.t(), Tag.label_or_labels(), keyword) :: t()
  def set_labels(taggable, ns, lbls, opts \\ [])

  @spec remove_labels(t(), Ns.t() | nil, Tag.label_or_labels()) :: t()
  def remove_labels(taggable, ns, lbls)

  @spec labels(t(), Ns.t() | nil) :: t()
  def labels(taggable, ns)
end
