defmodule StarknetExplorer.Repo.Migrations.TransactionReceipts do
  use Ecto.Migration

  def change do
    create table("transaction_receipts") do
      add :transaction_id,
          references(:transactions)

      add :type, :string
      add :actual_fee, :string
      add :status, :string
      add :block_hash, :string
      add :block_number, :integer
      add :messages, {:array, :map}, null: true
      add :messages_sent, {:array, :map}, null: true
      add :events, {:array, :map}, null: true
      add :contract_address, :string
      timestamps()
    end

    create unique_index("transaction_receipts", [:transaction_id])
  end
end
