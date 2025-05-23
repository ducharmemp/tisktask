import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :argon2_elixir, t_cost: 1, m_cost: 5

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
config :tisktask, Oban, testing: :manual

# In test we don't send emails
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :tisktask, Tisktask.Mailer, adapter: Swoosh.Adapters.Test

config :tisktask, Tisktask.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "tisktask_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  # We don't run a server during test. If one is required,
  # you can enable the server option below.
  pool_size: System.schedulers_online() * 2

config :tisktask, TisktaskWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "3E8b40Ed5snQywMpNuJ9fDLgkyn4/KnmTB7Ahz7HifdOPEa8pMAr/457beoLpnqK",
  server: false

config :tisktask,
  github_req_options: [plug: {Req.Test, Tisktask.SourceControl}]
