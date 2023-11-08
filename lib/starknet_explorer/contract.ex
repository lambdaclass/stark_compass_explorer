defmodule StarknetExplorer.Contract do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.Repo

  @networks [:mainnet, :testnet]
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
    :deployed_at_transaction,
    :block_number
  ]

  @required [
    :address,
    :class_hash,
    :network
  ]

  @primary_key false
  schema "contracts" do
    field :address, :string, primary_key: true
    field :network, Ecto.Enum, values: @networks, primary_key: true
    field :deployed_by_address, :string
    field :timestamp, :integer
    field :version, :string
    field :balance, :string
    field :type, :string
    field :nonce, :string
    field :class_hash, :string
    field :deployed_at_transaction, :string
    field :block_number, :integer

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> validate_required(@required)
    |> unique_constraint([:address, :network], name: :contracts_pkey)
  end

  def insert(event) do
    %StarknetExplorer.Contract{}
    |> changeset(event)
    |> Repo.insert()
  end

  def get_page_by_class_hash(params, class_hash, network) do
    StarknetExplorer.Contract
    |> where([p], p.class_hash == ^class_hash and p.network == ^network)
    |> order_by(desc: :timestamp)
    |> Repo.paginate(params)
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
