defmodule MinimalElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :minimal_elixir,
      version: "0.1.0",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.0"}
    ]
  end
end
