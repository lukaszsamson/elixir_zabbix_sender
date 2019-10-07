defmodule ZabbixSender.Serializer do
  @moduledoc ~S"""
  Helper module for binary serialization with Zabbix Sender Protocol
  """

  # Zabbix sender protocol definitions
  @protocol "ZBXD"
  @protocol_version "\x01"
  @header @protocol <> @protocol_version

  @doc ~S"""
  Serializes message to zabbix sender binary format.

  ## Examples
      iex> ZabbixSender.Serializer.serialize(%{})
      <<"ZBXD\x01"::binary, 2::little-integer-size(64), "{}"::binary>>
  """
  @spec serialize(map()) :: binary
  def serialize(msg) do
    encoded_msg = Jason.encode!(msg)
    <<@header::binary, byte_size(encoded_msg)::little-integer-size(64), encoded_msg::binary>>
  end

  @doc ~S"""
  Deserializes zabbix sender binary message to elixir data.

  ## Examples
      iex> ZabbixSender.Serializer.deserialize(<<"ZBXD\x01"::binary, 2::little-integer-size(64), "{}"::binary>>)
      {:ok, %{}}
      iex> ZabbixSender.Serializer.deserialize(<<"ZBX\x01"::binary, 1::little-integer-size(64), "{}"::binary>>)
      {:error, :invalid_format}
      iex> ZabbixSender.Serializer.deserialize(<<>>)
      {:error, :invalid_format}
      iex> ZabbixSender.Serializer.deserialize(<<"ZBXD\x02"::binary, 2::little-integer-size(64), "{}"::binary>>)
      {:error, :unsupported_version}
      iex> ZabbixSender.Serializer.deserialize(<<"ZBXD\x01"::binary, 2::little-integer-size(64), "{"::binary>>)
      {:error, :invalid_format}
      iex> ZabbixSender.Serializer.deserialize(<<"ZBXD\x01"::binary, 1::little-integer-size(64), "{}"::binary>>)
      {:error, :invalid_format}
      iex> ZabbixSender.Serializer.deserialize(<<"ZBXD\x01"::binary, 2::little-integer-size(64), "{w"::binary>>)
      {:error, %Jason.DecodeError{data: "{w", position: 1, token: nil}}
  """
  @spec deserialize(binary) ::
          {:error, :invalid_format | :unsupported_version | Jason.DecodeError.t()} | {:ok, map()}
  def deserialize(
        <<@protocol::binary, @protocol_version::binary, size::little-integer-size(64),
          msg::binary>>
      )
      when byte_size(msg) == size do
    Jason.decode(msg)
  end

  def deserialize(
        <<@protocol::binary, _protocol_version::size(8), size::little-integer-size(64),
          msg::binary>>
      )
      when byte_size(msg) == size do
    {:error, :unsupported_version}
  end

  def deserialize(_msg) do
    {:error, :invalid_format}
  end
end
