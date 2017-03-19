defmodule Wallaby.Mixfile do
  use Mix.Project

  @version "0.16.1"

  def project do
    [app: :wallaby,
     version: @version,
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     description: "Concurrent feature tests for elixir",
     deps: deps(),
     docs: docs(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test,
       "coveralls.html": :test, "coveralls.travis": :test
     ]
   ]
  end

  def application do
    [applications: [:logger, :httpoison, :poolboy, :poison], mod: {Wallaby, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:httpoison, "~> 0.11.0"},
      {:poison, ">= 1.4.0"},
      {:poolboy, "~> 1.5"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:earmark, "~> 1.1.1", only: :dev},
      {:ex_doc, "~> 0.15.0", only: :dev},
      {:quixir, "~> 0.9.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.6.2",  only: :test},
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "priv"],
      maintainers: ["Chris Keathley", "Tommy Fisher", "Alex Daniel"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/keathley/wallaby"}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: "https://github.com/keathley/wallaby",
      main: "readme",
    ]
  end
end
