# ZabbixSender

Zabbix Sender Protocol client. Compatible with [Zabbix 4.0](https://zabbix.org/wiki/Docs/protocols/zabbix_sender/4.0)

This library implements a simple TCP client as well as helper functions for encoding and decoding protocol messages.

## Installation

The package can be installed by adding `zabbix_sender` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zabbix_sender, "~> 1.0.0"}
  ]
end
```

## Usage

Use functions from `ZabbixSender.Protocol` for building requests and decoding responses.
Use `ZabbixSender.Serializer` for writting and reading binary messages.
`ZabbixSender.send\3` will open connection, send request receive a response and then close the connection as the server won't allow it remain open.

### Example

```elixir
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
```

## Documentation

Docs can be found at [https://hexdocs.pm/zabbix_sender](https://hexdocs.pm/zabbix_sender).

## License

ZabbixSender source code is released under MIT License.
Check LICENSE file for more information.
