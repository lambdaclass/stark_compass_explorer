defmodule StarknetExplorer.Repo.Migrations.AddClasses do
  use Ecto.Migration

  def change do
    create table("classes", primary_key: false) do
      add :hash, :string, primary_key: true

      add :block_number,
          references("blocks",
            on_delete: :delete_all,
            column: :number,
            name: :block_number,
            prefix: nil,
            type: :integer
          )

      add :declared_at_tx,
          references("transactions",
            on_delete: :delete_all,
            column: :hash,
            name: :declared_at_tx_hash,
            prefix: nil,
            type: :string
          )

      add :abi, :binary
      add :sierra_program, :binary
      add :declared_at, :integer
      add :version, :string
      add :state_update_json, :binary
      timestamps()
    end

    create unique_index("classes", [:hash])
  end
end
