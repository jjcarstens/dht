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
      {:ex_doc, "~> 0.23", only: :docs},
      # {:circuits_gpio, "~> 0.4"},
      {:elixir_make, "~> 0.6", runtime: false},
      {:telemetry_poller, "~> 0.5"}
    ]
  end

  defp description() do
    "Driver for DHT 11, DHT 22, and AM2302 temperature/humidity sensors"
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package() do
    [
      name: "dht",
      files: ["src", "lib", "mix.exs", "README.md", "LICENSE", "Makefile"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Adafruit DHT22/AM2302 Datasheet" =>
          "https://cdn-shop.adafruit.com/datasheets/Digital+humidity+and+temperature+sensor+AM2302.pdf",
        "SparkFun DHT22 Datasheet" =>
          "https://www.sparkfun.com/datasheets/Sensors/Temperature/DHT22.pdf",
        "Mouser DHT11 Datasheet" =>
          "https://www.mouser.com/datasheet/2/758/DHT11-Technical-Data-Sheet-Translated-Version-1143054.pdf"
      }
    ]
  end
end
