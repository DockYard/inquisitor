defmodule Inquisitor do
  @moduledoc """
  Composable query builder for Ecto.

  Inquisitor provides functionality to build a powerful query builder
  from a very simple pattern.

      defmodule App.PostController do
        use Inquisitor
      end

  This will inject the necessary code into the `App.PostController`
  module. The function name depends upon the schema name. In this case
  the function injected will be called `build_query/1`.

  The builder function expects a flat map of key/value pairs to be
  passed in. Typically this might be captured from an incoming request.

  `[GET] /posts?foo=hello&bar=world` may result in a params map of
  `%{"foo" => "hello", "bar" => "world"}`

      def index(conn, params) do
        posts =
          build_query(params)
          |> Repo.all()

        json(conn, posts)
      end

  ## Writing custom query handlers

  Custom query handlers are written using `defquery/2`. This macro
  has the `query` variable injected at compile-time so you can use it
  to build up a new query. The result of the this macro should always
  be the query. The first argument will be the param key to match on,
  the second is the value matcher:

      defquery "title", title do
        query
        |> Ecto.Query.where([r], r.title == ^title)
      end

  This macro will inject a new function at compile time. The above example
  will produce:

      def build_query(query, [{"title", title} | tail]) do
        query
        |> Ecto.Qiery.where([r], r.title == ^title)
        |> build_query(tail)
      end

  The macro is there for convenience. If you'd like to just write the function
  and avoid the macro you are free to do so.
  """
  defmacro __using__(_opts) do
    quote do
      import Inquisitor
      @before_compile Inquisitor
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def build_query(query, params) when is_map(params) do
        params = Map.to_list(params)

        build_query(query, params)
      end

      def build_query(query, []), do: query
      def build_query(query, [{_attr, _value}|tail]) do
        build_query(query, tail)
      end

      defoverridable [build_query: 2]
    end
  end

  Module.add_doc(__MODULE__, __ENV__.line + 2, :defmacro, {:defquery, 2}, (quote do: [field, value]), """
  Define new query matcher

  Query matcher macro, the `query` is automatically injected at compile-time for use in the block

  Usage

      defquery "name", name do
        query
        |> Ecto.Query.where([r], r.name == ^name)
      end

  You can also use guards with the macro:

      defquery attr, value when attr == "month" or attr == "year" do
        query
        |> Ecto.Query.where([e], fragment("date_part(?, ?) = ?", ^attr, e.inserted_at, type(^value, :integer)))
      end
  """)

  @doc false
  defmacro defquery(key, value, [do: do_expr]) do
    do_expr = Macro.prewalk(do_expr, fn
      {:query, meta, nil} -> {:query, meta, __MODULE__}
      node -> node
    end)

    [value, when_expr] = case value do
      {:when, _meta, expr} -> expr
      value -> [value, true]
    end

    quote do
      def build_query(query, [{unquote(key), unquote(value)} | tail]) when unquote(when_expr) do
        unquote(do_expr)
        |> build_query(tail)
      end
    end
  end
end
