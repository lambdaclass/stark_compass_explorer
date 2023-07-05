defmodule StarknetExplorer.Repo.Migrations.Transactions do
  use Ecto.Migration

  def change do
    create table("transactions", primary_key: false) do
      add :hash, :string, null: false, primary_key: true
      add :type, :string, null: false
      add :max_fee, :string, null: false
      add :version, :string, null: false
      add :signature, {:array, :string}, null: false
      add :nonce, :string, null: false
      add :contract_address, :string, null: false
      add :entry_point_selector, :string, null: false
      add :calldata, {:array, :string}, null: false
      add :block_number, references("blocks", column: :number, type: :integer, null: false)
      timestamps()
    end

    create unique_index("transactions", [:hash])

    alter table("blocks") do
      add :transactions, references("transactions", column: :hash, type: :string, null: false)
    end
  end
end
