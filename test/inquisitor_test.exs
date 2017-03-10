defmodule InquisitorTest do
  use ExUnit.Case

  defmodule Basic do
    require Ecto.Query
    use Inquisitor

    defquery "order_by", field do
      query
      |> Ecto.Query.order_by([asc: ^String.to_existing_atom(field)])
    end

    defquery "name", name do
      query
      |> Ecto.Query.where([r], r.name == ^name)
    end

    defquery "age", age when age == "20" do
      query
      |> Ecto.Query.where([r], r.age == 44)
    end

    defquery "age", age do
      query
      |> Ecto.Query.where([r], r.age == ^age)
    end
  end

  def to_sql(q) do
    Ecto.Adapters.SQL.to_sql(:all, Repo, q)
  end

  test "will build a simple key/value query" do
    q = Basic.build_query(User, %{"name" => "Brian"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age" FROM "users" AS u0 WHERE (u0."name" = $1)}, ["Brian"]}
  end

  test "will combine multiple params with AND sql" do
    q = Basic.build_query(User, %{"name" => "Brian", "age" => 36})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age" FROM "users" AS u0 WHERE (u0."age" = $1) AND (u0."name" = $2)}, [36, "Brian"]}
  end

  test "can use custom composable query" do
    q = Basic.build_query(User, %{"order_by" => "name"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age" FROM "users" AS u0 ORDER BY u0."name"}, []}
  end

  test "defquery can take guards" do
    q = Basic.build_query(User, %{"age" => "20"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age" FROM "users" AS u0 WHERE (u0."age" = 44)}, []}
  end
end
