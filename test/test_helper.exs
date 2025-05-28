ExUnit.start(exclude: [:skip])

Faker.start()
Mimic.copy(Tisktask.SourceControl.Git)
Mimic.copy(Tisktask.Containers.Buildah)
Mimic.copy(Tisktask.Containers.Podman)

Ecto.Adapters.SQL.Sandbox.mode(Tisktask.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)
