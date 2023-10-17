defmodule StarknetExplorer.Contract do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query
  alias StarknetExplorer.Repo

  @networks [:mainnet, :testnet, :testnet2]
  @fields [
    :deploted_by_address,
    :timestamp,
    :version,
    :balance,
    :type,
    :nonce,
    :network,
    :class_hash,
    :deployed_at_transaction
  ]

  @required [
    :class_hash,
    :network
  ]

  @primary_key {:address, :string, []}
  schema "contracts" do
    field :deployed_by_address, :string
    field :timestamp, :integer
    field :version, :string
    field :balance, :string
    field :type, :string
    field :nonce, :string
    field :network, Ecto.Enum, values: @networks
    timestamps()

    belongs_to :class_hash, StarknetExplorer.Class, references: :hash
    belongs_to :deployed_at_transaction, StarknetExplorer.Transaction, references: :hash
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> validate_required(@required)
  end

  def insert(event) do
    %StarknetExplorer.Contract{}
    |> changeset(event)
    |> Repo.insert()
  end
end
