defmodule StarknetExplorer.Repo.Migrations.AddEventsTable do
  use Ecto.Migration

  def change do
    create table("events", primary_key: false) do
      references("blocks",
        on_delete: :delete_all,
        column: :number,
        name: :block_number,
        prefix: nil,
        type: :integer
      )
      references("transactions",
      on_delete: :delete_all,
      column: :hash,
      name: :transaction_hash,
      prefix: nil,
      type: :string
    )

      add :name, :string
      add :from_address, :string
      add :age, :timestamp
      add :name_hashed, :string
      add :data, :json  # [felt]
      add :id, :string
      timestamps()
    end

    create unique_index("events", [:id])
  end
end
