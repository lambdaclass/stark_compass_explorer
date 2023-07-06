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
             :eth_balance,
             :deployed_by,
             :deployed_at_tx
           ] ++ @required

  @primary_key {:address, :string, []}
  schema "contracts" do
    field :eth_balance, :integer
    field :deployed_at, :integer
    field :version, :string

    belongs_to :block, StarknetExplorer.Block, references: :number
    belongs_to :deployed_by, __MODULE__
    belongs_to :deployed_at_tx, StarknetExplorer.Transaction, references: :hash
    belongs_to :class_hash, StarknetExplorer.Class

    timestamps()
  end

  def changeset(contract, attrs) do
    contract
    |> cast(
      attrs,
      @allowed
    )
    |> validate_required(@required)
    |> unique_constraint(:address)
  end

  def list(), do: Repo.all(__MODULE__)
end
