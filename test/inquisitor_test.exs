defmodule InquisitorTest do
  use ExUnit.Case

  @context %{}

  defmodule Basic do
    require Ecto.Query
    use Inquisitor

    def build_query(query, "order_by", field, _context) do
      Ecto.Query.order_by(query, [asc: ^String.to_existing_atom(field)])
    end

    def build_query(query, "name", name, _context) do
      Ecto.Query.where(query, [r], r.name == ^name)
    end

    def build_query(query, "age", age, _context) when age == "20" do
      Ecto.Query.where(query, [r], r.age == 44)
    end

    def build_query(query, "age", age, _context) do
      Ecto.Query.where(query, [r], r.age == ^age)
    end
  end

  def to_sql(query) do
    Ecto.Adapters.SQL.to_sql(:all, Repo, query)
  end

  test "will build a simple key/value query" do
    q = Basic.build_query(User, @context, %{"name" => "Brian"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age" FROM "users" AS u0 WHERE (u0."name" = $1)}, ["Brian"]}
  end

  test "will combine multiple params with AND sql" do
    q = Basic.build_query(User, @context, %{"name" => "Brian", "age" => 36})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age" FROM "users" AS u0 WHERE (u0."age" = $1) AND (u0."name" = $2)}, [36, "Brian"]}
  end

  test "can use custom composable query" do
    q = Basic.build_query(User, @context, %{"order_by" => "name"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age" FROM "users" AS u0 ORDER BY u0."name"}, []}
  end

  test "def build_query(query, can take guards" do
    q = Basic.build_query(User, @context, %{"age" => "20"})
    assert to_sql(q) == {~s{SELECT u0."id", u0."name", u0."age" FROM "users" AS u0 WHERE (u0."age" = 44)}, []}
  end
end
