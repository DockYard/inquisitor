use Mix.Config

config :inquisitor, Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "inquisitor_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  size: 1
