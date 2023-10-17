defmodule StarknetExplorer.Contract do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.Repo

  @networks [:mainnet, :testnet, :testnet2]
  @fields [
    :address,
    :deployed_by_address,
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
    :address,
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
    field :class_hash, :string
    field :deployed_at_transaction, :string
    timestamps()
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

  def get_page(params, network) do
    StarknetExplorer.Contract
    |> where([p], p.network == ^network)
    |> order_by(desc: :timestamp)
    |> Repo.paginate(params)
  end

  def get_by_address(address, network) do
    StarknetExplorer.Contract
    |> where([p], p.address == ^address and p.network == ^network)
    |> Repo.one()
  end
end
