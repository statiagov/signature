use Mix.Config

config :signature, Signature.Mailer,
  adapter: Bamboo.TestAdapter
