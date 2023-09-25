defmodule StarknetExplorer.Repo.Migrations.AddMessagesTable do
  use Ecto.Migration

  def change do
    create table("messages") do
      references("transactions",
        on_delete: :delete_all,
        column: :transaction_hash,
        name: :transaction,
        prefix: nil,
        type: :string
      )

      references("transaction_receipts",
        on_delete: :delete_all,
        column: :transaction_hash,
        name: :transaction_receipt,
        prefix: nil,
        type: :string
      )

      add :from_address, :string
      add :to_address, :string
      add :payload, {:array, :string}
      add :transaction_hash, :string
      add :message_hash, :string
      add :timestamp, :integer, null: false
      add :network, :string
      add :type, :string

      timestamps()
    end

    create unique_index("messages", [:message_hash])
  end
end
