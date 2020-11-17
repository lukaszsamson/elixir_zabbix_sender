defmodule ZabbixSender.LLDPusher do
  @moduledoc ~S"""
  Zabbix LLD pusher server. Attempts to send LLD via Zabbix Sender Protocol

  ## Usage
    def zabbix_config() do
      [host: "zabbix.host", port: 1234, hostname: "monitored.host"]
    end

    def zabbix_llds() do
      [
        some_trapper_key:
          for val <- [1, 2] do
            %{
              "{#VAL}" => "#{val}",
            }
          end,
      ]
    end

    children = [
      {ZabbixSender.LLDPusher,
         llds_provider: &__MODULE__.zabbix_llds/0, config_provider: &__MODULE__.zabbix_config/0}
    ]
  """

  use GenServer
  require Logger

  alias ZabbixSender.Protocol

  @retry_interval 5_000

  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]},
      restart: :temporary
    }
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    send(self(), :push)

    {:ok,
     %{
       llds_provider: args |> Keyword.fetch!(:llds_provider),
       config_provider: args |> Keyword.fetch!(:config_provider)
     }}
  end

  @impl GenServer
  def handle_info(
        :push,
        %{llds_provider: llds_provider, config_provider: config_provider} = state
      ) do
    llds = llds_provider.()
    config = config_provider.()
    timestamp = System.system_time(:second)

    values =
      for {key, value} <- llds do
        Protocol.value(
          config |> Keyword.fetch!(:hostname),
          Atom.to_string(key),
          value |> Jason.encode!(),
          timestamp
        )
      end

    total = length(llds)

    case ZabbixSender.send_values(
           values,
           timestamp,
           config |> Keyword.fetch!(:host),
           config |> Keyword.fetch!(:port)
         ) do
      {:ok, %{failed: 0, total: ^total}} ->
        Logger.info("Zabbix LLD pushed")
        {:stop, :normal, state}

      o ->
        Logger.error("Zabbix LLD push failed: #{inspect(o)}")
        Process.send_after(self(), :push, Enum.random(0..(2 * @retry_interval)))
        {:noreply, state}
    end
  end
end
