defmodule StarknetExplorer.Class do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query
  alias StarknetExplorer.Repo

  @networks [:mainnet, :testnet, :testnet2]

  @fields [
    :declared_by_address,
    :timestamp,
    :version,
    :type,
    :network,
    :hash,
    :declared_at_transaction,
    :declared_by_address
  ]

  @required [
    :hash,
    :network
  ]

  @primary_key {:hash, :string, []}
  schema "classes" do
    field :timestamp, :string
    field :declared_by_address, :string
    field :version, :string
    field :type, :string
    field :network, Ecto.Enum, values: @networks
    belongs_to :declared_at_transaction, StarknetExplorer.Transaction, references: :hash

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> validate_required(@required)
  end

  def insert(event) do
    %StarknetExplorer.Class{}
    |> changeset(event)
    |> Repo.insert()
  end
end
