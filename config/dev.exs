use Mix.Config

config :signature, Signature.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("STATIAGOVERNMENT_MAIL_API"),
  domain: System.get_env("STATIAGOVERNMENT_MAIL_DOMAIN")
