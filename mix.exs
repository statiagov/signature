defmodule Signature.Mixfile do
  use Mix.Project

  def project do
    [app: :signature,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: Signature],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :porcelain, :bamboo, :bamboo_smtp, :eex],
     mod: {Signature, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:porcelain, "~> 2.0"},
      {:bamboo, "~> 0.7"},
      {:bamboo_smtp, "~> 1.2.0"},
      {:csv, "~> 1.4.2"},
      {:vex, "~> 0.5.4"},
    ]
  end
end
