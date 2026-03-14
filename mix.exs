defmodule VibeCraft.MixProject do
  use Mix.Project

  def project do
    [
      app: :vibe_craft,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_targets: ["all"],
      make_clean: ["clean"],
      dialyzer: [
        plt_add_apps: [:mix],
        plt_local_path: "priv/plts",
        flags: [:error_handling, :missing_return, :underspecs]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {VibeCraft.Application, []}
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.8", runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
