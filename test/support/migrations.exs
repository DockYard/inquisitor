defmodule Inquisitor.Test.Migrations do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :age, :integer
      add :verified, :boolean
    end
  end
end
