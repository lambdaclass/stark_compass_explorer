defmodule StarknetExplorer.Class do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.Repo

  @networks [:mainnet, :testnet, :testnet2]

  @fields [
    :declared_by_address,
    :declared_at_transaction,
    :timestamp,
    :version,
    :network,
    :hash
  ]

  @required [
    :hash,
    :network
  ]

  @primary_key false
  schema "classes" do
    field :hash, :string, primary_key: true
    field :network, Ecto.Enum, values: @networks, primary_key: true
    field :timestamp, :integer
    field :declared_by_address, :string
    field :version, :string
    field :declared_at_transaction, :string

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> validate_required(@required)
    |> unique_constraint([:hash, :network], name: :classes_pkey)
  end

  def insert(params) do
    %StarknetExplorer.Class{}
    |> changeset(params)
    |> Repo.insert()
  end

  def get_page(params, network) do
    StarknetExplorer.Class
    |> where([p], p.network == ^network)
    |> order_by(desc: :timestamp)
    |> Repo.paginate(params)
  end

  def get_by_hash(hash, network) do
    StarknetExplorer.Class
    |> where([p], p.hash == ^hash and p.network == ^network)
    |> Repo.one()
  end
end
