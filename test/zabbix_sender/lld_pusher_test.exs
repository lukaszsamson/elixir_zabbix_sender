defmodule ZabbixSender.LLDPusherTest do
  use ExUnit.Case, async: false
  alias ZabbixSender.Serializer
  import Mock

  def llds() do
    [lld_key: [%{key: "value"}]]
  end

  def config do
    [
      host: "example.com",
      port: 1234,
      hostname: "my.host"
    ]
  end

  test "sends lld" do
    test_pid = self()

    with_mock ZabbixSender, [:passthrough],
      send: fn msg, "example.com", 1234 ->
        send(test_pid, :ok)
        {:ok, deserialized} = Serializer.deserialize(msg)

        assert [
                 %{
                   "clock" => _,
                   "host" => "my.host",
                   "key" => "lld_key",
                   "value" => "[{\"key\":\"value\"}]"
                 }
               ] = deserialized["data"]

        {:ok,
         Serializer.serialize(%{
           response: "success",
           info: "processed: 1; failed: 0; total: 1; seconds spent: 0.000055"
         })}
      end do
      {:ok, _pid} =
        ZabbixSender.LLDPusher.start_link(
          llds_provider: &__MODULE__.llds/0,
          config_provider: &__MODULE__.config/0
        )

      assert_receive :ok
    end
  end
end
