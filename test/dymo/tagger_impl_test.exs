defmodule Dymo.TaggerImplTest do
  use Dymo.TaggerImplTester,
    schema: Dymo.Post,
    primary_key: :post_id,
    join_table: "taggings"

  doctest TaggerImpl, include: true
end
