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
      package: package()
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
      {:circuits_gpio, "~> 0.4"},
      {:elixir_make, "~> 0.6"}
    ]
  end

  defp description() do
    "Drive of DHT 11 and DHT 22 (temperature and humidity sensor)"
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
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
