defmodule Wallaby.Mixfile do
  use Mix.Project

  @version "0.22.0"
  @drivers ~w(phantom selenium chrome)
  @selected_driver System.get_env("WALLABY_DRIVER")
  @maintainers [
    "Chris Keathley",
    "Tobias Pfeiffer",
    "Aaron Renner",
  ]

  def project do
    [app: :wallaby,
     version: @version,
     elixir: "~> 1.7",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     description: "Concurrent feature tests for elixir",
     deps: deps(),
     docs: docs(),

     # Custom testing
     aliases: ["test.all": ["test", "test.drivers"],
               "test.drivers": &test_drivers/1],
     preferred_cli_env: [
       coveralls: :test,
       "coveralls.detail": :test,
       "coveralls.post": :test,
       "coveralls.html": :test,
       "coveralls.travis": :test,
       "coveralls.safe_travis": :test,
       "test.all": :test,
       "test.drivers": :test],
     test_coverage: [tool: ExCoveralls],
     test_paths: test_paths(@selected_driver),
     dialyzer: [plt_add_apps: [:inets], ignore_warnings: "dialyzer.ignore_warnings"]]
  end

  def application do
    [extra_applications: [:logger], mod: {Wallaby, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  # need the testserver in dev for benchmarks to run
  defp elixirc_paths(:dev),  do: ["lib", "integration_test/support/test_server.ex"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:httpoison, "~> 0.12 or ~> 1.0"},
      {:poolboy, "~> 1.5"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.20", only: :dev},
      {:benchee, "~> 0.9", only: :dev},
      {:benchee_html, "~> 0.3", only: :dev},
      {:bypass, "~> 0.8", only: :test},
      {:inch_ex, "~> 0.5", only: [:docs]},
      {:excoveralls, "~> 0.7",  only: :test},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "priv"],
      maintainers: @maintainers,
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
      logo: "guides/images/icon.png",
    ]
  end

  defp test_paths(driver) when driver in @drivers, do: ["integration_test/#{driver}"]
  defp test_paths(_), do: ["test"]

  defp test_drivers(args) do
    for driver <- @drivers, do: run_integration_test(driver, args)
  end

  defp run_integration_test(driver, args) do
    args = if IO.ANSI.enabled?, do: ["--color" | args], else: ["--no-color" | args]

    IO.puts "==> Running tests for WALLABY_DRIVER=#{driver} mix test"
    {_, res} = System.cmd "mix", ["test" | args],
                          into: IO.binstream(:stdio, :line),
                          env: [{"WALLABY_DRIVER", driver}]

    if res > 0 do
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end
  end
end
