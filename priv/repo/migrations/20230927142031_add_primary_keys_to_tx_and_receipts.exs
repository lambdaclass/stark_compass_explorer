defmodule StarknetExplorer.Repo.Migrations.AddPrimaryKeysToTxAndReceipts do
  use Ecto.Migration

  def change do
    # Remove the existing primary key constraint
    execute("ALTER TABLE transactions DROP CONSTRAINT transactions_pkey CASCADE")

    # Set the "hash" column as the new primary key
    alter table(:transactions) do
      modify :hash, :string, primary_key: true
    end

    # Remove the existing primary key constraint
    execute("ALTER TABLE transaction_receipts DROP CONSTRAINT transaction_receipts_pkey CASCADE")

    # Set the "hash" column as the new primary key
    alter table(:transaction_receipts) do
      modify :transaction_hash, :string, primary_key: true
    end
  end
end
