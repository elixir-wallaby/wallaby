defmodule Wallaby.Mixfile do
  @moduledoc false
  use Mix.Project

  @version "0.1.5"
  @drivers ~w(selenium chrome)
  @selected_driver System.get_env("WALLABY_DRIVER")
  @maintainers [
    "Bob Waycott",
    "Brett Hazen",
    "James Edward Gray II"
  ]

  def project do
    [
      app: :wallaby,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: "Concurrent feature tests for elixir",
      deps: deps(),
      docs: docs(),

      # Custom testing
      aliases: aliases(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "test.all": :test,
        "test.drivers": :test
      ],
      test_coverage: [tool: ExCoveralls],
      test_paths: test_paths(@selected_driver),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [extra_applications: [:logger, :inets, :ssl], mod: {Wallaby, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  # need the testserver in dev for benchmarks to run
  defp elixirc_paths(:dev), do: ["lib", "integration_test/support/test_server.ex"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:poolboy, "~> 1.5"},
      {:web_driver_client, "~> 0.1.0"},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.4.1", only: [:dev, :test], runtime: false},
      {:bypass, "~> 1.0.0", only: :test},
      {:excoveralls, "~> 0.7", only: :test},
      {:ex_doc, "~> 0.20", only: :dev},
      {:inch_ex, "~> 2.0", only: :dev},
      {:ecto_sql, ">= 3.0.0", optional: true},
      {:phoenix_ecto, ">= 3.0.0", optional: true}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "priv"],
      exclude_patterns: ["safe_travis.ex"],
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/pay-it-off/wallaby/"}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: "https://github.com/pay-it-off/wallaby/",
      main: "readme",
      logo: "guides/images/icon.png"
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:inets, :phoenix_ecto, :ecto_sql],
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true
    ]
  end

  defp aliases do
    [
      "test.all": ["test", "test.drivers"],
      "test.drivers": &test_drivers/1,
      lint: [
        "compile --warnings-as-errors --force",
        "format --check-formatted",
        "credo",
        "test",
        "dialyzer"
      ]
    ]
  end

  defp test_paths(driver) when driver in @drivers, do: ["integration_test/#{driver}"]
  defp test_paths(_), do: ["test"]

  defp test_drivers(args) do
    for driver <- @drivers, do: run_integration_test(driver, args)
  end

  defp run_integration_test(driver, args) do
    args = if IO.ANSI.enabled?(), do: ["--color" | args], else: ["--no-color" | args]

    IO.puts("==> Running tests for WALLABY_DRIVER=#{driver} mix test")

    {_, res} =
      System.cmd("mix", ["test" | args],
        into: IO.binstream(:stdio, :line),
        env: [{"WALLABY_DRIVER", driver}]
      )

    if res > 0 do
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end
  end
end
