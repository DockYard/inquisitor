defmodule InquisitorTest do
  use ExUnit.Case
  use Inquisitor, with: User

  import Ecto.Query

  alias Ecto.Adapters.Postgres.Connection, as: SQL

  def to_sql(q) do
    Ecto.Adapters.SQL.to_sql(:all, Repo, q)
  end

  test "will build a simple key/value query" do
    q = build_user_query(%{"name" => "Brian"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."name" = $1)}, ["Brian"]}
  end 

  test "will combine multiple params with AND sql" do
    q = build_user_query(%{"name" => "Brian", "age" => 36})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."age" = $1) AND (u0."name" = $2)}, [36, "Brian"]}
  end

  test "will convert \"true\" to its boolean value" do
    q = build_user_query(%{"verified" => "true"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."verified" = $1)}, [true]}
  end

  test "will convert \"false\" to its boolean value" do
    q = build_user_query(%{"verified" => "false"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."verified" = $1)}, [false]}
  end

  test "can use custom composable query" do
    q = build_user_query(%{"limit" => 20})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 LIMIT $1}, [20]}
  end

  def build_user_query(query, [{"limit", limit}|t]) do
    query
    |> limit(^limit)
    |> build_user_query(t) 
  end
end
