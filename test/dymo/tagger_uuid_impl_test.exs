defmodule Dymo.TaggerUuidImplTest do
  use Dymo.TaggerImplTester,
    schema: Dymo.UUPost,
    primary_key: :uu_post_id,
    join_table: "taggings"
end
