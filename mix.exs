defmodule Studio.Mixfile do
  use Mix.Project

  def project do
    [app: :studio,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [
						:logger,
						:silverb,
						:sqlx,
						:exprotobuf,
						:timex,
						:cachex,
						:wwwest_lite,
						:jazz,
					],
     mod: {Studio, []}]
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
			{:silverb, github: "timCF/silverb"},
			{:sqlx, github: "timCF/sqlx"},
			{:exprotobuf, github: "bitwalker/exprotobuf"},
			{:timex, github: "bitwalker/timex", tag: "2.2.1"},
			{:cachex, github: "timCF/cachex"},
			{:wwwest_lite, github: "timCF/wwwest_lite"},
			{:jazz, github: "meh/jazz"},
		]
	end
end
