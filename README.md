# Dymo

[![Build Status](https://ci.linky.one/api/badges/tableturn/dymo/status.svg)](https://ci.linky.one/tableturn/dymo)
[![Coverage Report](https://codecov.io/gh/tableturn/dymo/branch/master/graph/badge.svg)](https://codecov.io/gh/tableturn/dymo)
[![Hex.pm](https://img.shields.io/hexpm/dt/dymo.svg)](https://hex.pm/packages/dymo)

![Dymo Embosser](https://i.ebayimg.com/00/s/ODQ3WDc2Ng==/z/5mwAAOSw1x1UNkFc/$_35.JPG?set_id=2)

For all your labelling and tagging needs!™

## Warning

Version `1.0.0` is **backward-incompatible** with other previous versions. Make sure to read the inline documentation to understand what this means, particularily the namespace fields that are required to be added on the `Tag` schema.

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

You should then configure Dymo to use the Repo you'd like. From your config, symply do:

```elixir
config :dymo,
  ecto_repo: MyApp.Repo,
  create_missing_tags_by_default: false
```

> Note that the `create_missing_tags_by_default` option is set to `false` by default if you omit it, more on this later in this README.

Then, you can install the `Tag` migration in your application (Note
that for umbrella apps, you'll need to first `cd` into the app
containing your repo migrations):

```text
$ mix dymo.install
* creating priv/repo/migrations
* creating priv/repo/migrations/20180828154957_create_tags.exs
```

Once done, you should start and make a join table for the model(s) you
want to be able to label. There is a mix task for this too!

```text
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

> Note that you can tweak the migrations. For example, you can rename the `posts_tags` table to whatever you want (eg. `taggings`) as long as you consistently specify it when using the `Tagger` macros:

```elixir
use Dymo.Taggable, join_table: "taggings"
```

Once your database gets migrated, a new table posts_tags will be created.

If you follow the directives given by the tasks, you should then have
a fully labellable Post model. Congratulations!

## Using Dymo.Taggable

When a module uses `Dymo.Taggable`, many shortcut functions are
backed into it.

It becomes easy to achieve labelling-related tasks. All the examples
bellow assyme that a `Post` module calls `use Dymo.Taggable`.

> If you would like to see more advanced uses and how Dymo's API works, a good starting point is probably [this file](test/dymo/end_to_end_test.exs), which calls on most functions that you'll ever need.

### Editing Labels

To set the tags on an instance of a post:

```elixir
post
  |> Taggable.set_labels(~w(ten eleven), ns: :number, create_missing: true)
  |> Taggable.set_labels([{:car, "Fort"}, {:color, "blue"}], create_missing: true)
  |> Taggable.set_labels("Heineken", ns: :beer, create_missing: true)
```

Similarily, you can add / remove labels using `Post.add_labels` and `Post.remove_labels`.

You can also force labelling to only use existing tags (avoid on-the-fly creation) by
passing appropriate options. For example:

```elixir
post
  |> Taggable.set_labels(~w(ten twelve), ns: :number, create_missing: false)
  |> Taggable.add_labels("Pierre", ns: :name, create_missing: false)
```

The default option for functions that either set or add labels is to **not** create non-
existent tags. Passing the `create_missing: true` option allows to create tags that were never seen
by the system before. The reason behind this choice is to prevent Dymo from inadvertently creating
infinite labels in your database if you ever decided to leave an endpoint open allowing that.

You can override this behaviour by doing the following in your `config` files:

```elixir
config :dymo, create_missing_tags_by_default: true
```

### Querying Labels

To get the labels associated with a given post, you have several options.

Using the association directly if you defined it:

```elixir
post
  |> Repo.preload(:tags)
  |> Map.get(:tags)
  |> Enum.map(&(&1.label))
```

Using the helper function:

```elixir
# If the namespace is unspecified, the `:root` namespace is used.
post
  |> Taggable.labels()
# Otherwise, only the labels from the given namespace are returned.
post
  |> Taggable.labels(ns: :number)
```

You can also query models that are tagged with specific labels by doing the following:

```elixir
# Match posts tagged with at least *one* of the tags.
Post |> Taggable.labelled_with(~w(ten eleven))
# Match posts tagged with at least *all* the specified tags.
Post |> Taggable.labelled_with([{:color, "blue"}, {"Heineken", :beer}], match_all: true)
```

## Notes

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dymo](https://hexdocs.pm/dymo).
