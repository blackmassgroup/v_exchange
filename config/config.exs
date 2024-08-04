# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

three_days = 259_200

config :v_exchange, Oban,
  repo: VExchange.Repo.Local,
  engine: Oban.Engines.Basic,
  queues: [default: 10, vxu_uploads: 1, file_uploads: 50],
  plugins: [
    {Oban.Plugins.Cron, crontab: [{"0 0 * * *", VExchange.ObanJobs.DailyUploader}]},
    {Oban.Plugins.Pruner, max_age: three_days},
    Oban.Plugins.Lifeline,
    Oban.Plugins.Reindexer
  ]

config :v_exchange, env: Mix.env()

config :v_exchange,
  ecto_repos: [VExchange.Repo.Local]

config :v_exchange, VExchange.Repo.Local,
  priv: "priv/repo",
  timeout: :infinity

# Configures the endpoint
config :v_exchange, VExchangeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: VExchangeWeb.ErrorHTML, json: VExchangeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: VExchange.PubSub,
  live_view: [signing_salt: "hnZZR7D2"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :v_exchange, VExchange.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :v_exchange, s3_bucket_name: System.get_env("S3_BUCKET_NAME")

config :logger, :discord,
  level: :info,
  bot_token: System.get_env("DISCORD_BOT_TOKEN"),
  channel_id: System.get_env("DISCORD_CHANNEL_ID")

config :sentry,
  dsn:
    "https://30f19d0c59e288153c88fb762e46cc3e@o4505897025470464.ingest.sentry.io/4505897042575360",
  included_environments: [:prod],
  environment_name: Mix.env(),
  integrations: [
    oban: [
      # Capture errors:
      capture_errors: true,
      # Monitor cron jobs:
      cron: [enabled: true]
    ]
  ]

config :tesla, :adapter, Tesla.Adapter.Hackney

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
