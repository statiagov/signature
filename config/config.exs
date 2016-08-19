# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :porcelain, goon_warn_if_missing: false

import_config "#{Mix.env}.exs"