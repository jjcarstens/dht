defmodule Dht.MixProject do
  use Mix.Project

  def project do
    [
      app: :dht,
      version: "0.1.0",
      elixir: "~> 1.9",
      compilers: [:elixir_make | Mix.compilers()],
      make_clean: ["clean"],
      make_targets: ["all"],
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:pigpiox, "~> 0.1"},
      {:circuits_gpio, "~> 0.4"}
    ]
  end
end
