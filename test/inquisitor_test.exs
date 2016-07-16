defmodule InquisitorTest do
  use ExUnit.Case

  defmodule Basic do
    use Inquisitor, with: User
    require Ecto.Query

    defp build_user_query(query, [{"order_by", field} | tail]) do
      query
      |> Ecto.Query.order_by([asc: ^String.to_existing_atom(field)])
      |> build_user_query(tail)
    end
  end

  def to_sql(q) do
    Ecto.Adapters.SQL.to_sql(:all, Repo, q)
  end

  test "will build a simple key/value query" do
    q = Basic.build_user_query(%{"name" => "Brian"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."name" = $1)}, ["Brian"]}
  end 

  test "will combine multiple params with AND sql" do
    q = Basic.build_user_query(%{"name" => "Brian", "age" => 36})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."age" = $1) AND (u0."name" = $2)}, [36, "Brian"]}
  end

  test "will convert \"true\" to its boolean value" do
    q = Basic.build_user_query(%{"verified" => "true"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."verified" = $1)}, [true]}
  end

  test "will convert \"false\" to its boolean value" do
    q = Basic.build_user_query(%{"verified" => "false"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."verified" = $1)}, [false]}
  end

  test "can use custom composable query" do
    q = Basic.build_user_query(%{"order_by" => "name"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 ORDER BY u0."name"}, []}
  end

  test "will limit results" do
    q = Basic.build_user_query(%{"limit" => 20})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 LIMIT $1}, [20]}

    q = Basic.build_user_query(%{"limit" => "5"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 LIMIT $1}, [5]}
  end

  defmodule Whitelist do
    use Inquisitor, with: User, whitelist: ["name"]
    require Ecto.Query
  end

  test "allows whitelisted fields to be queried" do
    q = Whitelist.build_user_query(%{"name" => "Brian"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0 WHERE (u0."name" = $1)}, ["Brian"]}
  end

  test "disallows fields not whitelisted to be queried" do
    q = Whitelist.build_user_query(%{"age" => 36})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age", u0."verified" FROM "users" AS u0}, []}
  end
end
