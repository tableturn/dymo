defprotocol Dymo.Taggable.Protocol do
  def set_labels(taggable, ns \\ nil, lbls)

  def add_labels(taggable, ns \\ nil, lbls)

  def remove_labels(taggable, ns \\ nil, lbls)

  def labels(taggable, ns \\ nil)
end
