# Migration Guide

## From 0.3.0 to 0.4.0

If you are using `< 0.3.0` please follow the `0.2.0 to 0.3.0` migration
guide below then use the `0.3.0 to 0.4.0` guide.

0.4.0 dropped the macro in favor of pure functions. It also no requires
the `conn` object be passed into query builder.

#### Changing your code

**Calling the builder**

```diff
def index(conn, params) do
  posts =
    App.Post
-   |> build_query(params)
+   |> build_query(conn, params)
    |> Repo.all()
```

**Custom key/value handlers**

```diff
-defquery "title", title do
+def build_query(query, "title", title, _conn) do
  query
  |> Ecto.Query.where([r], r.title == ^title)
end
```

That should be it!

## From 0.2.0 to 0.3.0

From 0.3.0 on Inquisitor took the role of being an unopinionated
primitive to be built upon and does not include any out of the box query
matchers. If you are migrating from 0.2.0 you will want to make the
following changes:

#### Change the `use` line

```diff
- use Inquisitor, with: App.Post, whitelist: ["title"]
+ use Inquisitor
```

No longer does Inquisitor take any options for the model/schema or a
whitelist. For the former we pass the queryable object directly into the
query function. For the whitelisting, by default Inquisitor is no-op for
all keys. So it is secure by default. You must opt in one key at a time.

#### Change the function name in your Index action

```diff
def index(conn, params) do
  posts =
-   params
-   |> build_post_query()
+   App.Post
+   |> build_query(params)
    |> Repo.all()
```

The generated function is no longer generic. In 0.2.0 if you were using
`build_post_query/2` that should be changed to `build_query/2`. Also,
note how `App.Post` is being passed into `build_query/2` as the first
arguemnt. This gives you greater control over what the starting
queryable object is.

#### Change your query matching functions to the new `defquery/2` macro

```diff
-defp build_post_query(query, [{"title", title}|tail]) do
-  query
-  |> Ecto.Query.where([r], r.title == ^title)
-  |> build_post_query(tail)
+defquery "title", title do
+  query
+  |> Ecto.Query.where([r], r.title == ^title)
end
```

The new `defquery/2` macro cuts down on the code and hopefully the
mistakes. The `query` is injected into the macro's scope at
compile-time. You no longer have to ensure you make the tail-call at the
end, this is do for you. Just ensure the result is the query.

### Other changes

* boolean preprocessing is gone, so you must match on `"true"` and `"false"` instead of `true` and `false`
* the `limit` matcher is gone, you should jsut write your own
* the default key/value matcher is gone. If you want this functionality back you should add it, but be aware that it will opt-in for every key. If you'd like to ensure some security you can use a guard with `defquery/2`

```elixir
defquery key, value when key in ["title"] do
  query
  |> Ecto.Query.where([r], field(r, ^String.to_existing_atom(attr)) == ^value
end
```
