defmodule StarknetExplorer.Repo.Migrations.AddEventsTable do
  use Ecto.Migration

  def change do
    create table("events", primary_key: false) do
      references("blocks",
        on_delete: :delete_all,
        column: :number,
        name: :block,
        prefix: nil,
        type: :integer
      )

      references("transactions",
        on_delete: :delete_all,
        column: :hash,
        name: :transaction,
        prefix: nil,
        type: :string
      )

      add :name, :string
      add :from_address, :string
      add :age, :integer
      add :name_hashed, :string
      # array of felts.
      add :data, {:array, :string}
      add :id, :uuid, primary_key: true
      add :index_in_block, :integer
      add :block_number, :integer
      add :transaction_hash, :string
      add :network, :string
      timestamps()
    end

    create unique_index("events", [:id])
    create index("events", [:transaction_hash])
  end
end
