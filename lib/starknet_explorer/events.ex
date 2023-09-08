defmodule StarknetExplorer.Events do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias StarknetExplorer.{Transaction, Repo, Block}
  @primary_key {:id, :string, autogenerate: false}
  @fields [
    :transaction_hash,
    :block_number,
    :name,
    :from_address,
    :age,
    :name_hashed,
    :data
  ]

  schema "events" do
    belongs_to :transaction_hash, Transaction
    belongs_to :block_number, Block
    field :name, :string
    field :from_address, :string
    field :age, :naive_datetime
    field :name_hashed, :string
    field :data, :binary, load_in_query: true
    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> unique_constraint(:id)
  end
end
