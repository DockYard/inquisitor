# Inquisitor #

Easily build composable queries for Ecto.

[![Build Status](https://secure.travis-ci.org/dockyard/inquisitor.svg?branch=master)](http://travis-ci.org/dockyard/inquisitor)

## Usage ##

Adding Inquisitor to a project is simple:

```elixir
defmodule MyApp.PostController do
  use Inquisitor, with: MyApp.Post

  def index(conn, params) do
    events =
      build_event_query(params)
      |> Repo.all()

    json(conn, events)
  end
end
```

After `use Inquisitor, with: MyApp.Post` a custom function is added to
the `MyApp.PostController`. In this case that function is
`build_event_query`. The name of the function is dynamically created
based upon the model name. So if the model was `MyApp.FooBarBaz` the
corresponding function would be `build_foo_bar_baz_query`.

This sets up a key/value queryable API for the `Post` model. Any
combination of fields on the model can be queried against. For example,
requesting `[GET] /posts?foo=bar&baz=qux` will create the query:

```sql
SELECT p0."foo", p0."baz" FROM posts as p0 WHERE (p0."foo" = $1) AND (p0."baz" = $1);
```

`$1` and `$2` will get the values of `"bar"` and `"qux"`,

### Adding custom query handlers ###

Simple key/value matching is not always what you want. In that case you
can define custom handlers for certain keys. Let's say you want to query
based upon `inserted_at` values, querying for all values that came on
and after that date:

```elixir
defmodule MyApp.PostsController do
  use Inquisitor, with: MyApp.Post

  def index(conn, params) do
    events =
      build_event_query(params)
      |> Repo.all()

    json(conn, events)
  end

  def build_event_query(query, [{"inserted_at", date}|tail]) do
    query
    |> where([p], p.inserted_at >= ^date)
    |> build_user_query(tail)
  end
end
```

The query is built recursively by iterating over all the params. If
there is a matching custom handler, it uses that otherwise defaults to
the key/value handler.

### Handing fields that don't exist on the model ###

The keys you query against don't need to exist on the model. Revisting
the date example, let's say we want to find all posts inserted for a
given month and year:

```elixir
def build_event_query(query, [{attr, value}|tail]) when attr == "month" or attr == "year" do
  query
  |> where(fragment("date_part(?, ?) = ?", ^attr, e.inserted_at, type(^value, :integer)))
  |> build_event_query(q, tail)
end
```

That's it!

### Built in handlers ###

There are a few built in handlers

#### Booleans ####

Booleans that come in as text will be typecast to an actual boolean
type then past on for handling. So even if the params come as:

```elixir
%{ "foo" => "true" }
```

You will want to pattern match on the actual boolean value:

```elixir
def build_event_query(query, [{"foo", true}|tail]) do
  ...
```

## Authors ##

* [Brian Cardarella](http://twitter.com/bcardarella)

[We are very thankful for the many contributors](https://github.com/dockyard/inquisitor/graphs/contributors)

## Versioning ##

This library follows [Semantic Versioning](http://semver.org)

## Want to help? ##

Please do! We are always looking to improve this library. Please see our
[Contribution Guidelines](https://github.com/dockyard/inquisitor/blob/master/CONTRIBUTING.md)
on how to properly submit issues and pull requests.

## Legal ##

[DockYard](http://dockyard.com/), Inc. &copy; 2016

[@dockyard](http://twitter.com/dockyard)

[Licensed under the MIT license](http://www.opensource.org/licenses/mit-license.php)
