# Dymo

[![Build Status](https://ci.linky.one/api/badges/tableturn/dymo/status.svg)](https://ci.linky.one/tableturn/dymo)
[![Coverage Report](https://codecov.io/gh/tableturn/dymo/branch/master/graph/badge.svg)](https://codecov.io/gh/tableturn/dymo)
[![Hex.pm](https://img.shields.io/hexpm/dt/dymo.svg)](https://hex.pm/packages/dymo)

![Dymo Embosser](https://i.ebayimg.com/00/s/ODQ3WDc2Ng==/z/5mwAAOSw1x1UNkFc/$_35.JPG?set_id=2)

For all your labelling and tagging needs!™

## Motivations

When it comes to polymorphism, it's always hard to find a match-all solution. Each known implementation have tradeoffs:

1. Real polymorphism (`taggable_id`, `taggable_type` on the `Taggings` model) breaks database level foreign keys, and makes requests slower.
2. Parent entity (Having each model have a `entity_id` refering to some `Entity` model) and having tags assigned to the `Entity` model via `entity_id` is cumbersome when performing complex queries and reverse queries.
3. Multiple nullable foreign keys on the `Taggings` model (Eg `user_id`, `post_id`) is a very good solution but it could become hard to maintain and enforce if many models are taggable.
4. One join table per taggable model (Eg `users_tags` and `posts_tags`) make it impossible to consolidate and search using SQL queries only.

This package offers an implementation that fits the 3rd and 4th approaches, and it offers shortcuts and mix tasks to make your life easier.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dymo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dymo, "~> 0.1.0"}
  ]
end
```

Then, you can install the `Tag` migration in your application (Note
that for umbrella apps, you'll need to first `cd` into the app
containing your repo migrations):

```
$ mix dymo.install
* creating priv/repo/migrations
* creating priv/repo/migrations/20180828154957_create_tags.exs
```

Once done, you should start and make a join table for the model(s) you
want to be able to label. There is a mix task for this too!

```
$ mix dymo.join_table MyApp.Post
* creating priv/repo/migrations
* creating priv/repo/migrations/20180828154958_create_posts_tags.exs
Once your database gets migrated, a new table posts_tags will be created.

You might want to add the following relationship to your MyApp.Post schema:
  many_to_many :tags, Dymo.Tag,
                join_through: "posts_tags",
                on_replace: :delete,
                unique: true

Alternativelly, you can simply use the `tags()` macro in your schema declaration,
as long as you `use Dymo.Taggable` at the top of your module.
```

Note that you can tweak the migrations. For example, you can rename the `posts_tags`
table to whatever you want (eg. `taggings`) as long as you consistently specify it
when using the `Tagger` macros:

```elixir
use Dymo.Taggable, join_table: "taggings"
```

Once your database gets migrated, a new table posts_tags will be created.

If you follow the directives given by the tasks, you should then have
a fully labellable Post model. Congratulations!

## Using Dymo.Taggable

When a module uses `Dymo.Taggable`, many shortcut functions are
meta-programmed into it.

It becomes easy to achieve labelling-related tasks. All the examples
bellow assyme that a `Post` module calls `use Dymo.Taggable`.

### Editing Labels

To set the tags on an instance of a post:

```elixir
Post.set_labels(post, nil, ~w(ten eleven))
```

Similarily, you can add / remove labels using `Post.add_labels` and `Post.remove_labels`.

You can also force labelling to only use existing tags (avoid on-the-fly creation) by
passing appropriate options. For example:

````elixir
post |> Post.set_labels(nil, ~w(ten eleven), create_missing: false)
post |> Post.add_labels("Whatever", create_missing: false)
``

### Querying Labels

To get the labels associated with a given post, you have several options.

Using the association directly if you defined it:

```elixir
post
  |> Repo.preload(:tags)
  |> Map.get(:tags)
  |> Enum.map(&(&1.label))
#
````

Using the helper function:

```elixir
post
  |> Post.labels()
```

Note that the `Post.labels/1` also accepts a module directly as an input - in that case it would return all labels that were ever associated with all posts.

You can also query models that are tagged with specific labels by doing the following:

```elixir
Post.labelled_with(~w(ten eleven))
```

## Notes

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dymo](https://hexdocs.pm/dymo).
