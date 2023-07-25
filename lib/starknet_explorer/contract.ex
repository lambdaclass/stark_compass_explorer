defmodule StarknetExplorer.Contract do
  use Ecto.Schema
  alias StarknetExplorer.Repo
  import Ecto.Changeset

  @required [
    :block_number,
    :deployed_at,
    :version
  ]

  @allowed [
             :eth_balance
           ] ++ @required
  @assocs [
    :deployed_by,
    :deployed_at_tx,
    :class_hash
  ]
  @primary_key {:address, :string, []}
  schema "contracts" do
    field :eth_balance, :integer
    field :deployed_at, :integer
    field :version, :string
    field :type, :string

    belongs_to :block, StarknetExplorer.Block,
      references: :number,
      primary_key: true,
      foreign_key: :block_number

    belongs_to :deployed_by, __MODULE__,
      references: :address,
      primary_key: true,
      foreign_key: :deployed_by_address

    belongs_to :deployed_at_tx, StarknetExplorer.Transaction,
      references: :hash,
      primary_key: true,
      foreign_key: :deployed_at_transaction

    belongs_to :class_hash, StarknetExplorer.Class,
      references: :hash,
      primary_key: true,
      foreign_key: :contract_class_hash

    timestamps()
  end

  def changeset(contract, attrs) do
    contract
    |> cast(
      attrs,
      @allowed
    )
    |> cast_assoc(:block)
    |> cast_assoc(:deployed_by)
    |> cast_assoc(:deployed_at_tx)
    |> cast_assoc(:class_hash)
    |> validate_required(@required)
    |> unique_constraint(:address)
  end

  def list(), do: Repo.all(__MODULE__)
end
