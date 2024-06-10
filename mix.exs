defmodule Wallaby.Mixfile do
  use Mix.Project

  @source_url "https://github.com/elixir-wallaby/wallaby"
  @version "0.30.9"
  @drivers ~w(selenium chrome)
  @selected_driver System.get_env("WALLABY_DRIVER")
  @maintainers ["Mitchell Hanberg"]

  def project do
    [
      app: :wallaby,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: "Concurrent feature tests for elixir",
      deps: deps(),
      docs: docs(),

      # Custom testing
      aliases: ["test.all": ["test", "test.drivers"], "test.drivers": &test_drivers/1],
      preferred_cli_env: [
        "test.all": :test,
        "test.drivers": :test
      ],
      test_paths: test_paths(@selected_driver),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Wallaby, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  # need the testserver in dev for benchmarks to run
  defp elixirc_paths(:dev), do: ["lib", "integration_test/support/test_server.ex"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:httpoison, "~> 0.12 or ~> 1.0 or ~> 2.0"},
      {:web_driver_client, "~> 0.2.0"},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:bypass, "~> 1.0.0", only: :test},
      {:ex_doc, "~> 0.28", only: :dev},
      {:ecto_sql, ">= 3.0.0", optional: true},
      {:phoenix_ecto, ">= 3.0.0", optional: true}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "priv"],
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{
        "Github" => @source_url,
        "Sponsor" => "https://github.com/sponsors/mhanberg"
      }
    ]
  end

  defp docs do
    [
      extras: ["README.md": [title: "Introduction"]],
      source_ref: "v#{@version}",
      source_url: @source_url,
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
