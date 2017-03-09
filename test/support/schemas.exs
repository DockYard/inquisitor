defmodule User do
  use Ecto.Schema

  schema "users" do
    field :name
    field :age, :integer
    field :verified, :boolean
  end
end
