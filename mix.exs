defmodule Dht.MixProject do
  use Mix.Project

  @source_url "https://github.com/jjcarstens/dht"
  @version "0.1.0"

  def project do
    [
      app: :dht,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs
      }
    ]
  end

  def application do
    [
      mod: {DHT.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :docs},
      {:circuits_gpio, "~> 0.4"},
      {:elixir_make, "~> 0.6"},
      # {:telemetry_poller, "~> 0.5"},
      # TODO: remove this once https://github.com/beam-telemetry/telemetry_poller/pull/47 merged
      {:telemetry_poller, github: "jjcarstens/telemetry_poller"}
    ]
  end

  defp description() do
    "Driver for DHT 11, DHT 22, and AM2302 temperature/humidity sensors"
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package() do
    [
      name: "nerves_dht",
      files: ["src", "lib", "mix.exs", "README.md", "LICENSE", "Makefile"],
      licenses: ["GNU 3.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
