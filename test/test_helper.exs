ExUnit.start(exclude: [:skip, :integration])

Faker.start()
Mimic.copy(Tisktask.SourceControl.Git)
Mimic.copy(Tisktask.Containers.Buildah)
Mimic.copy(Tisktask.Containers.Podman)
Mimic.copy(Tisktask.Commands)
Mimic.copy(Tisktask.Triggers)
Mimic.copy(Tisktask.Tasks.Env)
Mimic.copy(Tisktask.Tasks.Runner)
Mimic.copy(Tisktask.TaskLogs)

Ecto.Adapters.SQL.Sandbox.mode(Tisktask.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)
