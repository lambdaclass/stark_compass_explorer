defmodule StarknetExplorer.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:number, :integer, []}
  schema "transactions" do
    field :tx_json, :binary
    timestamps()
  end

  def changeset(block, attrs) do
    block
    |> cast(attrs, [
      :number,
      :status,
      :hash,
      :parent_hash,
      :new_root,
      :timestamp,
      :sequencer_address,
      :original_json
    ])
    |> validate_required([
      :number,
      :status,
      :hash,
      :parent_hash,
      :new_root,
      :timestamp,
      :sequencer_address,
      :original_json
    ])
    |> unique_constraint(:number)
    |> unique_constraint(:hash)
  end
end
