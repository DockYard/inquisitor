Logger.configure(level: :info)
ExUnit.start()

_ = Repo.__adapter__.storage_down(Repo.config)
:ok = Repo.__adapter__.storage_up(Repo.config)

{:ok, _pid} = Repo.start_link
