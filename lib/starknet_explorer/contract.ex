defmodule StarknetExplorer.Contracts do
  use Ecto.Schema
  # import Ecto.Changeset
  # import Ecto.Query

  @networks [:mainnet, :testnet, :testnet2]

  @primary_key {:address, :string, []}
  schema "contracts" do
    field :deployed_by_address, :string
    field :timestamp, :string
    field :version, :string
    field :balance, :string
    field :type, :string
    field :nonce, :string
    field :network, Ecto.Enum, values: @networks
    timestamps()

    belongs_to :class_hash, StarknetExplorer.Class, references: :hash
    belongs_to :deployed_at_transaction, StarknetExplorer.Transaction, references: :hash
  end
end
