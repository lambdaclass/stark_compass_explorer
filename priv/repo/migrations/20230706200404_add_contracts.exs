defmodule StarknetExplorer.Repo.Migrations.AddContracts do
  use Ecto.Migration

  def change do
    create table("contracts", primary_key: false) do
      add :address, :string, primary_key: true

      add :block_number,
          references("blocks",
            on_delete: :delete_all,
            column: :number,
            name: :block_number,
            prefix: nil,
            type: :integer
          )

      add :deployed_at_tx,
          references("transactions",
            on_delete: :delete_all,
            column: :hash,
            name: :deployed_at_tx,
            prefix: nil,
            type: :string
          )

      add :eth_balance, :integer
      add :deployed_at, :integer
      add :version, :string
      add :type, :string, null: true

      timestamps()
    end

    create unique_index("contracts", [:address])
  end
end
