Mix.Task.run("ecto.create", ["-r", "Dymo.Repo"])
Mix.Task.run("ecto.migrate", ["-r", "Dymo.Repo"])

Dymo.Repo.start_link()

ExUnit.start()
