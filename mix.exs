defmodule ZabbixSender.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/lukaszsamson/elixir_zabbix_sender"

  def project do
    [
      app: :zabbix_sender,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "ZabbixSender",
      source_url: @source_url,
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: @source_url
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp description do
    """
    Zabbix Sender Protocol client.
    """
  end

  defp package do
    [
      name: :cashaddr,
      files: ["lib", "mix.exs", ".formatter.exs", "README*", "LICENSE*"],
      maintainers: ["Łukasz Samson"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
