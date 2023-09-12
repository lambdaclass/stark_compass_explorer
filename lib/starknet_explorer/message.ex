defmodule StarknetExplorer.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.Repo
  alias StarknetExplorer.Transaction
  alias StarknetExplorerWeb.Utils

  @primary_key {:message_hash, :string, autogenerate: false}
  @second_key {:transaction_hash, :string}
  @fields [
    :from_address,
    :to_address,
    :payload,
    :type,
    :transaction_hash,
    :message_hash,
    :timestamp,
    :network
  ]

  schema "messages" do
    field :from_address, :string
    field :transaction_hash, :string
    field :to_address, :string
    field :payload, {:array, :string}
    field :timestamp, :integer
    field :type, :string
    field :network, Ecto.Enum, values: [:mainnet, :testnet, :testnet2]
    # belongs_to :transaction, Transaction, foreign_key: :transaction_hash, references: :hash
    timestamps()
  end

  def changeset(message, params, network) do
    message
    |> cast(params, @fields)
    |> foreign_key_constraint(:transaction_hash)
    |> validate_required(@fields)
  end

  def insert_from_transaction_receipt(receipt, network) do
    receipt
    |> StarknetExplorerWeb.Utils.atomize_keys()
    |> from_transaction_receipt()
    |> Enum.map(fn message ->
      %StarknetExplorer.Message{}
      |> changeset(
        message
        |> Map.put(:network, network)
        |> Map.put(:timestamp, receipt["timestamp"])
        |> Map.put(:transaction_hash, receipt["transaction_hash"]),
        network
      )
      |> Repo.insert!(returning: false)
    end)
  end

  def from_transaction_receipt(receipt) do
    Enum.map(receipt.messages_sent, fn message ->
      message = message |> StarknetExplorerWeb.Utils.atomize_keys()

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
        # TODO: this needs to be revisited once L1 messages are added and processed
        type: "Sent on L2",
        message_hash: String.downcase("0x" <> keccak_message_hash)
      }
    end)
  end
end
