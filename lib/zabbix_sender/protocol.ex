defmodule ZabbixSender.Protocol do
  @moduledoc ~S"""
  Helper module for creating Zabbix Sender Protocol messages and parsing responses
  """

  @doc ~S"""
  Builds zabbix value.

  ## Examples
      iex> ZabbixSender.Protocol.value("localhost", "key", 1.23, 1570451084)
      %{clock: 1570451084, host: "localhost", key: "key", value: "1.23"}
      iex> ZabbixSender.Protocol.value("localhost", "key", 23, nil)
      %{host: "localhost", key: "key", value: "23"}
  """
  @spec value(String.t(), String.t(), any, integer | nil) :: %{
          :host => String.t(),
          :key => String.t(),
          :value => String.t(),
          optional(:clock) => integer
        }
  def value(hostname, key, value, nil) do
    %{host: hostname, key: key, value: "#{value}"}
  end

  def value(hostname, key, value, timestamp) do
    %{host: hostname, key: key, value: "#{value}", clock: timestamp}
  end

  @doc ~S"""
  Encodes zabbix sender data request.

  ## Examples
      iex> ZabbixSender.Protocol.encode_request([], 1570451084)
      %{clock: 1570451084, data: [], request: "sender data"}
  """
  @spec encode_request(list(), integer) :: %{
          :request => String.t(),
          :data => list(),
          :clock => integer
        }
  def encode_request(data, timestamp) do
    %{
      request: "sender data",
      data: data,
      clock: timestamp
    }
  end

  @doc ~S"""
  Decodes zabbix sender data response.

  ## Examples
      iex> ZabbixSender.Protocol.decode_response(%{"response" => "success", "info" => "processed: 1; failed: 1; total: 2; seconds spent: 0.000055"})
      {:ok, %{failed: 1, processed: 1, seconds_spent: 5.5e-5, total: 2}}
      iex> ZabbixSender.Protocol.decode_response(%{"response" => "success", "info" => "failed: 1; total: 2; seconds spent: 0.000055"})
      {:ok, %{failed: 1, processed: nil, seconds_spent: 5.5e-5, total: 2}}
      iex> ZabbixSender.Protocol.decode_response(%{"response" => "error"})
      {:error, :unexpected_response}
  """
  @spec decode_response(map) ::
          {:error, :unexpected_response}
          | {:ok, %{failed: integer, processed: integer, seconds_spent: number, total: integer}}
  def decode_response(%{"response" => "success", "info" => info}) do
    info_parts =
      info
      |> String.split("; ")
      |> Enum.map(&(&1 |> String.split(": ")))

    total = info_parts |> get_info_part("total", &String.to_integer/1)
    failed = info_parts |> get_info_part("failed", &String.to_integer/1)
    processed = info_parts |> get_info_part("processed", &String.to_integer/1)
    seconds_spent = info_parts |> get_info_part("seconds spent", &String.to_float/1)

    {:ok,
     %{
       total: total,
       failed: failed,
       processed: processed,
       seconds_spent: seconds_spent
     }}
  end

  def decode_response(_other) do
    {:error, :unexpected_response}
  end

  defp get_info_part(info_parts, part, transform) do
    case info_parts |> Enum.find(&match?([^part, _], &1)) do
      [_, val] -> transform.(val)
      nil -> nil
    end
  end
end
