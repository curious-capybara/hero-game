import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :game_web, GameWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Ap802wGiYQbZTsGNaBShGhCwZcDyeFmdhbbWYYN/m9rfD1DUDHYd05D3q4GYQ6Bp",
  server: false

# In test we don't send emails.
config :game_web, GameWeb.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
