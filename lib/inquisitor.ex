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
  the function injected will be called `build_query/3`.

  The builder function expects a flat map of key/value pairs to be
  passed in. Typically this might be captured from an incoming request.

  `[GET] /posts?foo=hello&bar=world` may result in a params map of
  `%{"foo" => "hello", "bar" => "world"}`

      def index(conn, params) do
        posts =
          Post
          |> build_query(conn, params)
          |> Repo.all()

        json(conn, posts)
      end

  ## Writing custom query handlers

  Custom query handlers are written using `build_query/4`. They accumulatd
  query is the first argument. The key/value pairs
  extracted from the params become the 2nd and 3rd argument. The `conn` is the last argument.

  The return value of the function *must* be a query.

      def build_query(query, "title", title, _conn) do
        Ecto.Query.where(query, [r], r.title == ^title)
      end

  """
  defmacro __using__(_opts) do
    quote do
      @before_compile Inquisitor
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def build_query(query, %Plug.Conn{} = conn, params) do
        Enum.reduce(params, query, fn({key, value}, query) ->
          build_query(query, key, value, conn)
        end)
      end

      def build_query(query, _key, _value, %Plug.Conn{} = _conn), do: query
      defoverridable [build_query: 4]
    end
  end
end
