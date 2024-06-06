defmodule ZabbixSender do
  @moduledoc ~S"""
  Zabbix Sender Protocol client
  ## Examples
      value = ZabbixSender.Protocol.value("localhost", "some_key", 12.3, :os.system_time(:second))
      request = ZabbixSender.Protocol.encode_request([value], :os.system_time(:second))
      |> ZabbixSender.Serializer.serialize()

      with {:ok, response} <- ZabbixSender.send(request, "localhost", 10051),
        {:ok, deserialized} <- ZabbixSender.Serializer.deserialize(response),
        {:ok, decoded} <- ZabbixSender.Protocol.decode_response(deserialized)
      do
        if decoded.failed == 0 do
          Logger.info("#{decoded.processed} values processed")
        else
          Logger.warn("#{decoded.processed} values processed out of #{decoded.total}")
        end
      end
  """

  alias ZabbixSender.{
    Protocol,
    Serializer
  }

  @doc ~S"""
  Sends binary message to zabbix trapper endpoint and receives response.
  Returns binary response or an error.

  ## Examples
      iex> ZabbixSender.send(<<>>, "localhost", 12345)
      {:error, :econnrefused}
  """
  @spec send(binary, String.t(), integer) :: {:ok, binary} | {:error, any}
  def send(msg, host, port) do
    case :gen_tcp.connect(~c"#{host}", port, active: false) do
      {:ok, sock} ->
        result =
          with :ok <- :gen_tcp.send(sock, msg),
               {:ok, resp} <- :gen_tcp.recv(sock, 0) do
            {:ok, IO.iodata_to_binary(resp)}
          end

        # the server doesn't allow to keep the connection open
        :gen_tcp.close(sock)

        result

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc ~S"""
  Sends values collection to zabbix trapper endpoint and receives response.
  Returns deserialized response or an error.

  ## Examples
      iex> ZabbixSender.send_values([%{"key" => "value"}], 123412, "localhost", 12345)
      {:error, :econnrefused}
  """
  @spec send_values(nonempty_list(), pos_integer(), String.t(), integer) ::
          {:ok, Protocol.response_t()} | {:error, any}
  def send_values(values, timestamp, host, port) do
    serialized_message =
      values
      |> Protocol.encode_request(timestamp)
      |> Serializer.serialize()

    with {:ok, response} <- ZabbixSender.send(serialized_message, host, port),
         {:ok, deserialized} <- Serializer.deserialize(response) do
      Protocol.decode_response(deserialized)
    end
  end
end
