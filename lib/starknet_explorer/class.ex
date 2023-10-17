defmodule StarknetExplorer.Class do
  use Ecto.Schema
  # import Ecto.Changeset
  # import Ecto.Query

  @networks [:mainnet, :testnet, :testnet2]

  @primary_key {:hash, :string, []}
  schema "classes" do
    field :timestamp, :string
    field :declared_by_address, :string
    field :version, :string
    field :network, Ecto.Enum, values: @networks
    belongs_to :declared_at_transaction, StarknetExplorer.Transaction, references: :hash

    timestamps()
  end
end
