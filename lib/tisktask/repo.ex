defmodule Tisktask.Repo do
  use Ecto.Repo,
    otp_app: :tisktask,
    adapter: Ecto.Adapters.Postgres
end
