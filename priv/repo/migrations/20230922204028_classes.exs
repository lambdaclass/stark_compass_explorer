defmodule StarknetExplorer.Repo.Migrations.Classes do
  use Ecto.Migration

  def change do
    create table("classes") do
      references("transactions",
        on_delete: :delete_all,
        column: :declared_at_transaction_hash,
        name: :transaction,
        prefix: nil,
        type: :string
      )

      add :class_hash, :string, primary_key: true, null: false
      add :name, :string
      add :type, :string
      add :declared_by_contract_address, :string
      add :declared_at_transaction_hash, :string
      add :timestamp, :integer
      add :version, :string
      add :abi, {:array, :map}
      add :entry_points_by_type, :map
      add :program, :string
      add :sierra_program, {:array, :string}
      add :network, :string
      timestamps()
    end

    create unique_index("classes", [:class_hash])
  end
end
