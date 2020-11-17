defmodule ZabbixSenderTest do
  use ExUnit.Case, async: true

  doctest ZabbixSender
  doctest ZabbixSender.Protocol
  doctest ZabbixSender.Serializer
end
