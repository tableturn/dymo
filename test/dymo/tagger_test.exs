defmodule Dymo.TaggerTest do
  use ExUnit.Case, async: true
  alias Dymo.Tagger

  test ".join_table/1 infers naming convention correctly" do
    assert "people_tags" == Tagger.join_table(Person)
    assert "dogs_tags" == Tagger.join_table(Dog)
    assert "posts_tags" == Tagger.join_table(%Dymo.Post{})
  end

  test ".join_key/1 infers naming convention correctly" do
    assert :person_id == Tagger.join_key(Person)
    assert :dog_id == Tagger.join_key(Dog)
    assert :post_id == Tagger.join_key(%Dymo.Post{})
  end
end
