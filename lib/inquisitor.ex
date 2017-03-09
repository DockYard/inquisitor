defmodule Inquisitor do
  @fn_attr :inquisitor_fn_name
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
    Module.put_attribute(__CALLER__.module, @fn_attr, :build_query)

    quote do
      import Inquisitor
      @before_compile Inquisitor
    end
  end

  defmacro __before_compile__(env) do
    fn_name = Module.get_attribute(env.module, @fn_attr)

    quote do
      def unquote(fn_name)(query, params) when is_map(params) do
        params = Map.to_list(params)

        unquote(fn_name)(query, params)
      end

      def unquote(fn_name)(query, []), do: query
      def unquote(fn_name)(query, [{_attr, _value}|tail]) do
        unquote(fn_name)(query, tail)
      end

      defoverridable [{unquote(fn_name), 2}]
    end
  end

  defmacro defquery(key, value, [do: do_expr]) do
    fn_name = Module.get_attribute(__CALLER__.module, @fn_attr)

    do_expr = Macro.prewalk(do_expr, fn
      {:query, meta, nil} -> {:query, meta, __MODULE__}
      node -> node
    end)

    [value, when_expr] = case value do
      {:when, _meta, expr} -> expr
      value -> [value, true]
    end

    quote do
      def unquote(fn_name)(query, [{unquote(key), unquote(value)} | tail]) when unquote(when_expr) do
        unquote(do_expr)
        |> unquote(fn_name)(tail)
      end
    end
  end
end
