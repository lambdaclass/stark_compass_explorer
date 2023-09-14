defmodule StarknetExplorer.Messages do
  # @message [
  #   :from_address,
  #   :to_address,
  #   :payload,
  #   :transaction_hash,
  #   :message_hash,
  # ]

  def from_transaction_receipt(receipt) do
    Enum.map(receipt.messages_sent, fn message ->
      message =
        message
        |> StarknetExplorerWeb.Utils.atomize_keys()

      hash_input =
        Abi.encode_packed_mixed([
          message.from_address,
          message.to_address,
          length(message.payload),
          message.payload
        ])

      keccak_message_hash = Base.encode16(ExKeccak.hash_256(hash_input))

      %{
        transaction_hash: receipt.transaction_hash,
        from_address: message.from_address,
        to_address: message.to_address,
        payload: message.payload,
        message_hash: String.downcase("0x" <> keccak_message_hash)
      }
    end)
  end
end
