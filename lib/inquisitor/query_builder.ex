defmodule Inquisitor.QueryBuilder do
  @moduledoc """
  Behaviour for building queries with Inquisitor.
  """

  @type query :: Ecto.Query.t()
  @type key :: String.t() | atom
  @type value :: term()
  @type context :: map()

  @doc """
  Callback to handle specific values when building the query.

  For instance, you may have a column in your schema that is always lowercase.

      @impl Inquisitor.QueryBuilder
      def build_query(%Ecto.Query{} = query, "email", value, _) do
        Ecto.Query.where(query, email: ^String.downcase(value))
      end

  end
  """
  @callback build_query(query, key, value, context) :: query
end
