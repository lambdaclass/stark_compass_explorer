defmodule StarknetExplorer.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.Repo
  alias StarknetExplorer.Transaction
  alias StarknetExplorerWeb.Utils

  @primary_key {:id, :string, autogenerate: false}
  @fields [
    :from_address,
    :to_address,
    :payload,
    :transaction_hash,
    :timestamp,
    :message_hash,
    :network
  ]

  schema "messages" do
    belongs_to :transaction_hash, Transaction, references: :hash
    field :from_address, :string
    field :to_address, :string
    field :payload, {:array, :string}
    # field :transaction_hash, :string
    field :message_hash, :string
    field :timestamp, :integer
    # field :id, :string
    field :network, Ecto.Enum, values: [:mainnet, :testnet, :testnet2]
    timestamps()
  end

  def changeset(message, params, network) do
    message
    |> cast(params, @fields -- [:transaction_hash])
    |> cast_assoc(:transaction_hash, with: &Transaction.changeset/2)
    |> foreign_key_constraint(:transaction_hash)
    |> unique_constraint(:id)
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
        |> Map.put(:network, network),
        network
      )
      |> IO.inspect()
      |> Repo.insert()
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
        message_hash: String.downcase("0x" <> keccak_message_hash)
      }
    end)
  end
end
