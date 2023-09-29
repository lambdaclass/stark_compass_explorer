defmodule StarknetExplorer.Calldata.Test do
  alias StarknetExplorer.Calldata
  use ExUnit.Case

  test "Decode calldata field" do
    result = Calldata.from_plain_calldata(sample_calldata(), "0x0")
    assert length(result) == 2
  end

  def sample_calldata() do
    [
      "0x2",
      "0xda114221cb83fa859dbdb4c44beeaa0bb37c7537ad5ae66fe5e0efd20e6eb3",
      "0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c",
      "0x0",
      "0x3",
      "0x4270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f",
      "0x1171593aa5bdadda4d6b0efde6cc94ee7649c3163d5efeb19da6c16d63a2a63",
      "0x3",
      "0x12",
      "0x15",
      "0x4270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f",
      "0x303be685d97790000",
      "0x0",
      "0xda114221cb83fa859dbdb4c44beeaa0bb37c7537ad5ae66fe5e0efd20e6eb3",
      "0x303be685d97790000",
      "0x0",
      "0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
      "0x7916e059cecf10",
      "0x0",
      "0x77e0e33a3094ac",
      "0x0",
      "0x535c3a156333fbe70652d2badae994b3458a8265b3877f84463c2cd81363e03",
      "0x0",
      "0x0",
      "0x1",
      "0xda114221cb83fa859dbdb4c44beeaa0bb37c7537ad5ae66fe5e0efd20e6eb3",
      "0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
      "0x28c858a586fa12123a1ccb337a0a3b369281f91ea00544d0c086524b759f627",
      "0x64",
      "0x1",
      "0x0"
    ]
  end
end
