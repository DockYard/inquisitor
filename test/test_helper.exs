Logger.configure(level: :info)
ExUnit.start()

Code.require_file "./support/models.exs", __DIR__
Code.require_file "./support/repo.exs", __DIR__
Code.require_file "./support/migrations.exs", __DIR__

defmodule Inquisitor.Integration.Case do
  use ExUnit.CaseTemplate

  setup_all do
    Ecto.Adapters.SQL.begin_test_transaction(Repo, [])
    on_exit fn -> Ecto.Adapters.SQL.rollback_test_transaction(Repo, []) end
    :ok
  end

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(Repo, [])
    :ok
  end
end

_ = Ecto.Storage.down(Repo)
:ok = Ecto.Storage.up(Repo)

{:ok, _pid} = Repo.start_link
:ok = Ecto.Migrator.up(Repo, 0, Inquisitor.Test.Migrations, log: false)
Process.flag(:trap_exit, true)
